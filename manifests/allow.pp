# Defined type to manage hosts.allow
define tcpwrappers::allow(
  Enum['present', 'absent'] $ensure      = 'present',
  Data                      $client      = $name,
  Optional[String]          $comment     = undef,
  Tcpwrappers::Daemon       $daemon      = 'ALL',
  Boolean                   $enable_ipv6 = true,
  Optional[String]          $except      = undef,
  Tcpwrappers::Order        $order       = '100',
) {
  tcpwrappers::entry { $name :
    ensure      => $ensure,
    action      => 'allow',
    client      => $client,
    comment     => $comment,
    daemon      => $daemon,
    enable_ipv6 => $enable_ipv6,
    except      => $except,
    order       => $order,
  }
}
