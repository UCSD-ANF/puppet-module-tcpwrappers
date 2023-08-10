require 'ipaddr'

# Convert argument into TCP Wrappers-friendly version
Puppet::Functions.create_function(:'tcpwrappers::normalize_client') do
  dispatch :normalize_client do
    param 'Variant[String[1], Array[String[1]]]', :clients
    param 'Boolean', :allow_ipv6
  end

  def normalize_client(clients, allow_ipv6)
    # Validate input, and split single string into multiple array elements
    myarr = validate_clients(clients)

    retarr = [] # array to populate.
    myarr.each do |client|
      v = nil # var to modify (or not).

      # Convert to IPAddr if we can.
      begin
        ip = IPAddr.new(client)
      rescue ArgumentError => e
        # Do nothing if client is a Hostname, FQDN, suffix,
        # filename,keyword,etc.

        unless ['ALL', 'LOCAL', 'PARANOID'].include?(client) ||
               client =~ %r{^\.?[a-z\d_\.\-]+$} ||
               client =~ %r{^\/[^ \n\t,:#]+$}
          raise Puppet::ParseError, "#{__method__}: invalid spec: #{client}, #{e}"
        end
      else
        # process IPv4.
        if ip.ipv4?
          masklen = ip.prefix()
          netmask = IPAddr.new('255.255.255.255').mask(masklen)

          v = case masklen
              when 8 # /8
                ip.to_s.split('.').slice(0, 1).join('.') + '.'
              when 16 # /16
                ip.to_s.split('.').slice(0, 2).join('.') + '.'
              when 24 # /24
                ip.to_s.split('.').slice(0, 3).join('.') + '.'
              when 32 # /32
                ip.to_s
              else # Some other valid IPv4 IP/netmask.
                "#{ip}/#{netmask}"
              end
        # process IPv6.
        elsif ip.ipv6?
          # Some versions of tcpd cannot handle IPv6, so we want to be
          # able to filter data like this
          next unless allow_ipv6

          masklen = client.split('/')[1] || 128

          unless masklen.to_i <= 128 && masklen.to_i >= 0
            raise Puppet::ParseError, "#{__method__}: invalid spec: #{client}, #{e}"
          end

          v = masklen.eql?(128) ? "[#{ip}]" : "[#{ip}]/#{masklen}"
        end
      end
      retarr.push(v || client) # Add selected value to array.
    end
    retarr.join(' ') # Join on space, return
  end

  def validate_clients(clients)
    if clients.is_a? Array
      clients.each do |i|
        unless i.is_a? String
          raise Puppet::ParseError, "#{__method__}: expecting Array of Strings, got #{i.class}."
        end

        next unless i.include?(' ')
        raise Puppet::ParseError, "#{__method__}: expecting Array of Strings without spaces. " \
          "Got '#{i}'."
      end
      myarr = clients
    else
      myarr = clients.split(' ')
      if clients.empty?
        raise Puppet::ParseError, "#{__method__}: argument must contain text."
      end
    end

    myarr # return the parsed arguments
  end
end
