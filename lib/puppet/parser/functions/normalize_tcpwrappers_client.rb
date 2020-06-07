require 'ipaddr'

module Puppet::Parser::Functions
  newfunction(:normalize_tcpwrappers_client,
              type: :rvalue,
              doc: 'Convert argument into TCP Wrappers-friendly version',) do |args|

    # Validate input
    raise Puppet::ParseError, "#{__method__}: expecting 2 argument." \
      unless args.length == 2

    raise Puppet::ParseError.new(
      "#{__method__}: expecting String or Array, got #{args[0].class}.",
    ) \
      unless args[0].is_a?(String) || args[0].is_a?(Array)

    if args[0].is_a? Array
      args[0].each do |i|
        raise Puppet::ParseError.new(
          "#{__method__}: expecting Array of Strings, got #{i.class}.",
        ) \
          unless i.is_a? String

        raise Puppet::ParseError.new(
          "#{__method__}: expecting Array of Strings without spaces. " \
          "Got '#{i}'.",
        ) if i.include?(' ')
      end
      myarr = args[0]
    else
      myarr = args[0].split(' ')
      raise Puppet::ParseError.new(
        "#{__method__}: argument must contain text.",
      ) if args[0].empty?
    end

    # Output IPv6?
    args[1].is_a?(TrueClass) || args[1].is_a?(FalseClass) ||
      raise Puppet::ParseError, "#{__method__}: 2nd argument must true or false."

    # iterate over each string after we split on space
    retarr = [] # array to populate.
    myarr.each do |client|
      v = nil # var to modify (or not).

      # Convert to IPAddr if we can.
      begin
        ip = IPAddr.new(client)
      rescue ArgumentError => e
        # Do nothing if client is a Hostname, FQDN, suffix,
        # filename,keyword,etc.
        case client
        when 'ALL', 'LOCAL', 'PARANOID' then
        when %r{^\.?[a-z\d_\.\-]+$} then
        when /^\/[^ \n\t,:#]+$/ then
          # all NOOP
        else
          raise Puppet::ParseError.new(
            "#{__method__}: invalid spec: #{client}, #{e}",
          )
        end
      else
        # process IPv4.
        if ip.ipv4?
          masklen = client.split('/')[1] || 32
          netmask = IPAddr.new('255.255.255.255').mask(masklen)

          v = case netmask.to_i
          when 4_278_190_080 # /8
            ip.to_s.split('.').slice(0, 1).join('.') + '.'
          when 4_294_901_760 # /16
            ip.to_s.split('.').slice(0, 2).join('.') + '.'
          when 4_294_967_040 # /24
            ip.to_s.split('.').slice(0, 3).join('.') + '.'
          when 4_294_967_295 # /32
            ip.to_s
          else # Some other valid IPv4 IP/netmask.
            "#{ip}/#{netmask}"
              end
        # process IPv6.
        elsif ip.ipv6?
          # Some versions of tcpd cannot handle IPv6, so we want to be
          # able to filter data like this
          next unless args[1]

          masklen = client.split('/')[1] || 128

          raise Puppet::ParseError.new(
            "#{__method__}: invalid spec: #{client}, #{e}",
          ) \
            unless masklen.to_i <= 128 && masklen.to_i >= 0

          v = masklen.eql?(128) ? "[#{ip}]" : "[#{ip}]/#{masklen}"
        end
      end
      retarr.push(v || client) # Add selected value to array.
    end
    retarr.join(' ') # Join on space, return
  end
end
