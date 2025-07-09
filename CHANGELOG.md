# Changelog

All notable changes to this project will be documented in this file.

## Release 0.4.0

**Features**
* Modernized module for Puppet 7.34.0 and 8.x compatibility
* Updated PDK to 3.4.0 from 2.7.4
* Added support for AlmaLinux 8, 9 and Rocky Linux 8, 9
* Expanded operating system support to include newer versions:
  - CentOS 7, 8
  - Oracle Linux 7, 8, 9
  - RedHat 8, 9
  - Debian 10, 11, 12
  - Ubuntu 20.04, 22.04, 24.04
  - FreeBSD 12, 13, 14
  - macOS 11+ (Darwin 20+)
* Updated dependency versions:
  - stdlib: >= 6.0.0 < 10.0.0
  - concat: >= 6.0.0 < 9.0.0
* Enhanced CI testing with Puppet 7.34.0 and 8.x support

**Bugfixes**
* Removed deprecated stdlib validation functions:
  - Replaced validate_bool() with native Puppet data types
  - Replaced validate_slength() with native length checking
* Fixed parameter ordering in tcpwrappers::entry to comply with Puppet lint rules
* Fixed Ruby style issues in normalize_client function (removed unnecessary parentheses)
* Updated documentation with proper data type annotations

**Known Issues**
* None
