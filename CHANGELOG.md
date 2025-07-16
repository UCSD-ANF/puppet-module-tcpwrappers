# Changelog

All notable changes to this project will be documented in this file.

## Release 0.5.0

**Features**
* **BREAKING CHANGE**: Dropped support for Puppet 6.x - minimum version is now Puppet 7.0.0
* Enhanced Puppet 8 support with updated dependency versions:
  - stdlib: >= 8.0.0 < 11.0.0 (was >= 6.0.0 < 10.0.0)
  - concat: >= 7.0.0 < 10.0.0 (was >= 6.0.0 < 9.0.0)
* Updated CI configurations to focus on Puppet 7 and 8 testing
* Confirmed full compatibility with Puppet 8.10.0
* All 2518 unit tests pass successfully with Puppet 8

**Bugfixes**
* Removed legacy Puppet 6 support from CI pipelines
* Updated minimum Ruby version to 2.7.0 (aligned with Puppet 7+ requirements)

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
* **Significantly improved test coverage from 64.71% to 77.78%**
  - Added comprehensive test cases for all defined types
  - Enhanced function tests with edge cases and error conditions
  - Added tests for IPv6 handling, different client types, and validation
  - Expanded class tests to cover ensure => absent and IPv6 disabled scenarios
  - Increased test count from 389 to 750 examples
  - All tests pass with zero failures

**Bugfixes**
* Removed deprecated stdlib validation functions:
  - Replaced validate_bool() with native Puppet data types
  - Replaced validate_slength() with native length checking
* Fixed parameter ordering in tcpwrappers::entry to comply with Puppet lint rules
* Fixed Ruby style issues in normalize_client function (removed unnecessary parentheses)
* Updated documentation with proper data type annotations
* Fixed duplicate resource conflicts in test specifications

**Known Issues**
* None
