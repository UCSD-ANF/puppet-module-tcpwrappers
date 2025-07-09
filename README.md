# Tcpwrappers

## Overview

Manages _hosts.allow_ and _hosts.deny_.

* Requires [puppetlabs/concat](https://forge.puppet.com/puppetlabs/concat) (>= 6.0.0 < 9.0.0)
* Requires [puppetlabs/stdlib](https://forge.puppet.com/puppetlabs/stdlib) (>= 6.0.0 < 10.0.0)

## Compatibility

* **Puppet**: 6.21.0 to 8.x
* **Ruby**: 2.5.7 to 3.2.x

Tested on:
* CentOS/RHEL 7, 8
* Oracle Linux 7, 8, 9
* AlmaLinux 8, 9
* Rocky Linux 8, 9
* Scientific Linux 7
* Debian 10, 11, 12
* Ubuntu 20.04, 22.04, 24.04
* FreeBSD 12, 13, 14
* macOS 11+ (Darwin 20+)
* Solaris 11

## Usage

### `tcpwrappers`
```puppet
include tcpwrappers
```

#### Parameters
The following optional parameters are available:

* `ensure` (Enum['present', 'absent'])
    * Whether we should have *any* tcpd files around, `present` or `absent`.
    Default: `present`.
* `deny_by_default` (Boolean)
    * Installs the default `ALL:ALL` _hosts.deny_ entry if true.
    Default: `true`.
* `enable_hosts_deny` (Boolean)
    * Puts rejection ACLs in `/etc/hosts.deny` if true. Otherwise, all
    entries are places in `/etc/hosts.allow` and appended with either
    `:ALLOW` or `:DENY`. In this case, `/etc/hosts.deny` is also deleted.
    Default: `false`
* `enable_ipv6` (Boolean)
    * Whether to enable IPv6 support. Some platforms don't support IPv6.
    Default: `true`.

### `tcpwrappers::allow` and `tcpwrappers::deny`
1. Both `tcpwrappers::allow` or `tcpwrappers::deny` add the specified
entry to _hosts.allow_ (or _hosts.deny_ if `enable_hosts_deny` is `true`).
2. The `name` variable is not significant if the `client` parameter is used.
3. Both types may be called without explicitly calling the `tcpwrappers` class.

#### EXAMPLES

##### Simple client specification
```puppet
    tcpwrappers::allow { '10.0.2.0/24': }
    tcpwrappers::deny  { '10.0.0.0/8':  }
```
##### Allow more specific, deny less specific
```puppet
    # By default, allow comes before default, so:
    tcpwrappers::allow { '10.0.3.1': }
    tcpwrappers::deny  { '10.0.3.0/24': }

    # ...is equivalent to:
    tcpwrappers::allow { '10.0.3.1':
      daemon => 'ALL',
      order  => '100',
    }
    tcpwrappers::deny { '10.0.3.0/24':
      daemon => 'ALL',
      order  => '200',
    }
```
##### Deny more specific, allow less specific
To deny a single host, but allow the rest of the subnet, ensure the order
(requires `enable_hosts_deny` to be _false_ -- the default):
```puppet
    tcpwrappers::deny  { '10.0.3.1': order => '099' }
    tcpwrappers::allow { '10.0.1.0/24': }
```
##### Multiple clients
Specifying multiple subnets can happen a couple different ways:
```puppet
    tcpwrappers::allow { ['10.0.1.0/24','10.0.2.0/24']: }

    tcpwrappers::allow { 'my fav subnets':
      comment => 'Need to allow favorite subnets to ALL',
      client  => ['10.0.1.0/24','10.0.2.0/24', 'taco.example.com', 'jerkface'],
    }

    tcpwrappers::allow { 'my fav subnets to sshd':
      client => ['10.0.1.0/24','10.0.2.0/24'],
      daemon => 'sshd',
    }
```

##### With an exception specification
```puppet
    tcpwrappers::allow { 'ALL':
        daemon => 'mydaemon',
        client => 'ALL',
        except => '/etc/hosts.deny.inc',
    }
```
#### Parameters
The following optional parameters are available:

* `ensure` (Enum['present', 'absent'])
    * Whether the entry should be 'present' or 'absent'.  Default: `present`.
* `client` (Data)
    * The client specification to be added.  May be a string or array of
    strings. Each string must evaluate to a valid IPv4 or IPv6 address, subnet,
    or a hostname/FQDN.
    Default: `$name`.
* `comment` (Optional[String])
    * A comment to go above the entry. Default: `undef`.
* `daemon` (Tcpwrappers::Daemon)
    * The identifier supplied to libwrap by the daemon, often just the
    process name. Default: `ALL`.
* `except` (Optional[String])
    * Another client specification, acting as a filter for the first
    client specification. Default: `undef`.
* `order` (Tcpwrappers::Order)
    * The 3-digit number (as a String), signifying the order the line appears in the
    file. Default is `100` for tcpwrappers::allow and `200` for
    tcpwrappers::deny.
* `enable_ipv6` (Boolean)
    * Whether to enable IPv6 support for this entry. Default: `true`.

The `client` (or `name`) and `except` parameters must have one of the
following forms:

Type           | Example
-------------- | -------
FQDN:          | `example.com`
Domain suffix: | `.example.com`
IP address:    | `192.0.2.1`
IP prefix:     | `192.` `192.0.` `192.0.2.`
IP range:      | `192.0.2.0/24` `192.0.2.0/255.255.255.0`
Filename:      | `/path/to/file.acl`
Keyword:       | `ALL` `LOCAL` `PARANOID`

The client specification will be normalized before being matched
against or added to the existing entries in _hosts.allow_/_hosts.deny_.


## See also

hosts.allow(5)
