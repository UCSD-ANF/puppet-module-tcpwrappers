require 'ipaddr'

module Puppet::Parser::Functions
	newfunction(:normalize_tcpwrappers_client, :type => :rvalue, :doc => "Converts the argument into a TCP Wrappers-friendly client specification") do |args|
		args.length == 1 or raise Puppet::Error.new("normalize_tcpwrappers_client: excepting 1 argument")
		client = args[0]
		if not client.is_a? String
			raise Puppet::Error.new("normalize_tcpwrappers_client: argument must be a String")
		end

		case client
		when /^(\d+\.)(\d+\.\d+\.\d+\/(8|255\.0\.0\.0))?$/
			$1
		when /^(\d+\.\d+\.)(\d+\.\d+\/(16|255\.255\.0\.0))?$/
			$1
		when /^(\d+\.\d+\.\d+\.)(\d+\/(24|255\.255\.255\.0))?$/
			$1
		when /^(\d+\.\d+\.\d+\.\d+)(\/(32|255\.255\.255\.255))?$/
			$1
		when /^(\d+\.\d+\.\d+\.\d+)\/(\d+)$/
			ip      = $1
			masklen = $2
			ip      = IPAddr.new(ip).mask(masklen).to_s
			netmask = IPAddr.new("255.255.255.255").mask(masklen).to_s
			"#{ip}/#{netmask}"
		when /^\.?[a-z\d_.]+$/, /^\/[^ \n\t,:#]+$/, "ALL", "LOCAL", "PARANOID"
			# Hostname, FQDN, suffix, filename, keyword, etc.
			client
		else
			raise Puppet::Error.new("normalize_tcpwrappers_client: invalid spec: #{client}")
		end
	end
end
