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
end
