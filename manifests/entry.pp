# A defined type to manage entries in hosts.{allow,deny}.
# Should only be called by either tcpwrappers::allow or tcpwrappers::deny.
# @api private
define tcpwrappers::entry (
  Enum['present', 'absent'] $ensure,
  Enum['allow', 'deny']     $action,
  Data                      $client,
  Tcpwrappers::Daemon       $daemon,
  Boolean                   $enable_ipv6,
  Tcpwrappers::Order        $order,
  Optional[String]          $except      = undef,
  Optional[String]          $comment     = undef,
) {
  assert_private(
  'tcpwrappers::entry for module use only. Use allow or deny types')

  include tcpwrappers
  $enable_hosts_deny = $tcpwrappers::enable_hosts_deny

  $client_real = tcpwrappers::normalize_client($client,$enable_ipv6)
  $except_real = $except ? {
    undef   => '',
    default => tcpwrappers::normalize_client($except,$enable_ipv6),
  }
  $target_real = $enable_hosts_deny ? {
    true  => "/etc/hosts.${action}",
    false => '/etc/hosts.allow',
  }
  $key = regsubst(downcase(join([
          'tcpd',
          $action,
          $daemon,
          $name,
  ],' ')),'\W+','_','G')

  # Concat temp filename based on $key.
  # Most filesystems don't allow for >256 chars.
  if length($key) > 255 {
    fail("Key length ${length($key)} exceeds maximum of 255 characters")
  }

  if 'present' == $ensure {
    concat::fragment { $key :
      target  => $target_real,
      content => template('tcpwrappers/entry.erb'),
      order   => $order,
    }
  }
}
