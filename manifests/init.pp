# Initialization class for tcpwrappers module.
#
# @param ensure - if absent, hosts.allow and hosts.deny are emptied, and packages are removed.
# @param deny_by_default - if true, insert an ALL:ALL DENY entry
# @param enable_hosts_deny - defaults to false.
#   NOTE: Almost any modern version of tcpd can accept an ACL option at
#   the end of the line, e.g. ': ALLOW' or ': DENY'. In addition to
#   making debugging more obvious by containing all settings in a single
#   file, BSD kernels notably list /etc/hosts.deny as deprecated. So, we
#   want all entries in /etc/hosts.allow to be the default behavior. See
#   `man 5 hosts_options` on your OS for details.
# @param enable_ipv6 - defaults to true. Some platforms don't support ipv6.
class tcpwrappers (
  Enum['present', 'absent'] $ensure            = 'present',
  Boolean                   $deny_by_default   = true,
  Boolean                   $enable_hosts_deny = false,
  Boolean                   $enable_ipv6       = true,
) {
  $manage_owner = 'root'
  $manage_group = $facts['os']['family'] ? {
    'FreeBSD' => 'wheel',
    default   => 'root',
  }

  if $enable_hosts_deny {
    $concat_target = ['/etc/hosts.allow','/etc/hosts.deny']
  } else {
    $concat_target = '/etc/hosts.allow'
    file { '/etc/hosts.deny':
      ensure  => 'absent',
      require => Concat[$concat_target],
    }
  }

  $tcpd_name = $facts['os']['family'] ? {
    'Debian' => 'tcpd',
    'RedHat' => 'tcp_wrappers',
    default  => undef,
  }

  Tcpwrappers::Allow { enable_ipv6 => $enable_ipv6 }
  Tcpwrappers::Deny { enable_ipv6 => $enable_ipv6 }

  # Set up concat resource(s).
  concat { $concat_target :
    ensure => $ensure,
    group  => $manage_group,
    mode   => '0644',
    order  => 'numeric',
    owner  => $manage_owner,
    warn   => true,
  }

  # Conditionally install
  if $tcpd_name {
    ensure_packages($tcpd_name, { before => Concat[$concat_target] })
  }

  tcpwrappers::allow { 'localhost':
    ensure  => $ensure,
    comment => 'default allow localhost',
    order   => '001',
    client  => [
      'localhost',
      'localhost.localdomain',
      'localhost4','localhost4.localdomain4',
      'localhost6','localhost6.localdomain6',
      '127.0.0.0/8',
      '::1',
    ],
  }

  if $deny_by_default == true {
    tcpwrappers::deny { 'ALL':
      ensure  => $ensure,
      comment => 'default deny everything',
      order   => '999',
    }
  }
}
