# Defined type to manage hosts.deny
# @param ensure - add or remove the entry. Defaults to present.
# @param client - the hostname, ip address, or identifier of the client. Defaults to the resource name.
# @param comment - optional comment to include with the tcpwrappers entry
# @param daemon - the daemon targeted by the tcpwrappers entry, eg "sshd". Defaults to "ALL"
# @param enable_ipv6 - if true, allow ipv6 style entries. Not all tcpwrappers implementations can handle ipv6, so this can be disabled on
#        a case-by-case basis.
# @param except - an exception clause for tcpwrappers rules. Same format as client.
# @param order - the order of the entry. Defaults to 200 (after the default of 100 for allow entries)
define tcpwrappers::deny (
  Enum['present', 'absent'] $ensure      = 'present',
  Data                      $client      = $name,
  Optional[String]          $comment     = undef,
  Tcpwrappers::Daemon       $daemon      = 'ALL',
  Boolean                   $enable_ipv6 = true,
  Optional[String]          $except      = undef,
  Tcpwrappers::Order        $order       = '200',
) {
  tcpwrappers::entry { $name :
    ensure      => $ensure,
    action      => 'deny',
    client      => $client,
    comment     => $comment,
    daemon      => $daemon,
    enable_ipv6 => $enable_ipv6,
    except      => $except,
    order       => $order,
  }
}
