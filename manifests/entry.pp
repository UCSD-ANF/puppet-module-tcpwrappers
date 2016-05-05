# A defined type to manage entries in hosts.{allow,deny}.
# Should only be called by either tcpwrappers::allow or tcpwrappers::deny.
define tcpwrappers::entry(
  $ensure,
  $action,
  $client,
  $comment,
  $daemon,
  $enable_ipv6,
  $except,
  $order,
) {
  assert_private(
    'tcpwrappers::entry for module use only. Use allow or deny types')

  validate_bool($enable_ipv6)
  validate_re($action, '^(allow|deny)$')
  validate_re($daemon, '^(?:\w[\w.-]*\w|\w)$')
  validate_re($ensure, '^(ab|pre)sent$')
  validate_re($order,  '^[0-9]{3}$')
  if undef != $comment { validate_string($comment) }
  if undef != $except  { validate_string($except)  }

  include tcpwrappers
  $enable_hosts_deny = $tcpwrappers::enable_hosts_deny
  validate_bool($enable_hosts_deny)

  $client_real = normalize_tcpwrappers_client($client,$enable_ipv6)
  $except_real = $except ? {
    undef   => '',
    default => normalize_tcpwrappers_client($except,$enable_ipv6),
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
  validate_slength($key,255)

  if 'present' == $ensure {
    concat::fragment { $key :
      target  => $target_real,
      content => template('tcpwrappers/entry.erb'),
      order   => $order,
    }
  }
}
