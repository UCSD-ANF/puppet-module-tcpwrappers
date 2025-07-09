# frozen_string_literal: true

require 'spec_helper'

describe 'tcpwrappers::normalize_client' do
  it 'raises a ParseError if there is less than 2 arguments' do
    is_expected.to run.with_params([])
                      .and_raise_error(ArgumentError, %r{expects 2 arguments})
  end

  it 'raises a ParseError when client type is wrong' do
    is_expected.to run.with_params({}, false)
                      .and_raise_error(ArgumentError, %r{expects a .*, got Hash})
  end

  it 'raises an error when client type is a nested array' do
    is_expected.to run.with_params(['foo', 'bar', ['baz', 'qux'], 'nux'], false)
                      .and_raise_error(ArgumentError)
  end
  it 'passes a hostname through unchanged' do
    is_expected.to run.with_params('localhost', false)
                      .and_return('localhost')
    is_expected.to run.with_params('my-hyphenated-host.example.com', false)
                      .and_return('my-hyphenated-host.example.com')
  end

  it 'converts IPv4 class A networks into simpler form' do
    is_expected.to run.with_params('10.0.0.0/8', false)
                      .and_return('10.')
  end

  it 'converts IPv4 class B networks into simpler form' do
    is_expected.to run.with_params('192.168.0.0/16', false)
                      .and_return('192.168.')
  end

  it 'converts IPv4 class C networks into simpler form' do
    is_expected.to run.with_params('192.168.0.0/24', false)
                      .and_return('192.168.0.')
  end

  it 'converts IPv4 other sized networks into complex form' do
    is_expected.to run.with_params('172.16.0.0/12', false)
                      .and_return('172.16.0.0/255.240.0.0')
  end

  it 'surrounds IPv6 with brackets' do
    is_expected.to run.with_params('::1', true)
                      .and_return('[::1]')
  end

  it 'surrounds simplified IPv6 with brackets' do
    is_expected.to run.with_params('0000:0000:0000:0000:0000:0000:0000:0001', true)
                      .and_return('[::1]')
  end

  it 'surrounds IPv6 with brackets, but not the CIDR netmask' do
    is_expected.to run.with_params('fc00::/7', true)
                      .and_return('[fc00::]/7')
  end

  it 'combines client types into a single string joined by spaces' do
    is_expected.to run.with_params(['172.16.0.0/12', '10.0.0.0/8', 'fc00::/7'], true)
                      .and_return('172.16.0.0/255.240.0.0 10. [fc00::]/7')
  end

  it 'combines client types into a single string and strips out IPv6 if necessary' do
    is_expected.to run.with_params(['172.16.0.0/12', '10.0.0.0/8', 'fc00::/7'], false)
                      .and_return('172.16.0.0/255.240.0.0 10.')
  end

  it 'handles single IPv4 address' do
    is_expected.to run.with_params('192.168.1.1', false)
                      .and_return('192.168.1.1')
  end

  it 'handles keyword ALL' do
    is_expected.to run.with_params('ALL', false)
                      .and_return('ALL')
  end

  it 'handles keyword LOCAL' do
    is_expected.to run.with_params('LOCAL', false)
                      .and_return('LOCAL')
  end

  it 'handles keyword PARANOID' do
    is_expected.to run.with_params('PARANOID', false)
                      .and_return('PARANOID')
  end

  it 'handles domain suffix' do
    is_expected.to run.with_params('.example.com', false)
                      .and_return('.example.com')
  end

  it 'handles file path' do
    is_expected.to run.with_params('/etc/hosts.allow.custom', false)
                      .and_return('/etc/hosts.allow.custom')
  end

  it 'handles IPv6 with full address' do
    is_expected.to run.with_params('2001:db8::1', true)
                      .and_return('[2001:db8::1]')
  end

  it 'handles IPv6 with /128 subnet' do
    is_expected.to run.with_params('2001:db8::1/128', true)
                      .and_return('[2001:db8::1]/128')
  end

  it 'handles IPv6 with non-standard subnet' do
    is_expected.to run.with_params('2001:db8::/32', true)
                      .and_return('[2001:db8::]/32')
  end

  it 'handles hyphenated hostname' do
    is_expected.to run.with_params('web-server-01.example.com', false)
                      .and_return('web-server-01.example.com')
  end

  it 'handles underscored hostname' do
    is_expected.to run.with_params('web_server_01', false)
                      .and_return('web_server_01')
  end

  it 'handles mixed array with IPv4 and IPv6' do
    is_expected.to run.with_params(['192.168.1.0/24', '::1', 'localhost'], true)
                      .and_return('192.168.1. [::1] localhost')
  end

  it 'handles mixed array with IPv4 and IPv6 disabled' do
    is_expected.to run.with_params(['192.168.1.0/24', '::1', 'localhost'], false)
                      .and_return('192.168.1. localhost')
  end

  it 'handles invalid IPv4 format as hostname' do
    is_expected.to run.with_params('192.168.1.256', false)
                      .and_return('192.168.1.256')
  end

  it 'handles hostname with spaces as valid' do
    is_expected.to run.with_params('bad host name', false)
                      .and_return('bad host name')
  end

  it 'raises error for empty string (type validation)' do
    is_expected.to run.with_params('', false)
                      .and_raise_error(ArgumentError, /expects a value of type String\[1\]/)
  end

  it 'raises error for invalid IPv6 netmask' do
    is_expected.to run.with_params('::1/129', true)
                      .and_raise_error(Puppet::ParseError, /invalid spec:/)
  end

  it 'raises error for negative IPv6 netmask' do
    is_expected.to run.with_params('::1/-1', true)
                      .and_raise_error(Puppet::ParseError, /invalid spec:/)
  end

  it 'handles space-separated string input' do
    is_expected.to run.with_params('192.168.1.0/24 10.0.0.0/8', false)
                      .and_return('192.168.1. 10.')
  end

  it 'raises error for array with string containing spaces' do
    is_expected.to run.with_params(['192.168.1.0/24', '10.0.0.0/8 badentry'], false)
                      .and_raise_error(Puppet::ParseError, /expecting Array of Strings without spaces/)
  end

  it 'raises error for array with non-string elements (type validation)' do
    is_expected.to run.with_params(['192.168.1.0/24', 123], false)
                      .and_raise_error(ArgumentError, /expects a String value, got Integer/)
  end
end
