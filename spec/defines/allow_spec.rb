require 'spec_helper'

describe 'tcpwrappers::allow', type: 'define' do
  let(:title) { '10.0.0.0/255.0.0.0' }

  shared_examples_for 'a supported platform' do
    context 'with bad title' do
      let(:title) { '192.168/16' }

      it 'raises error due no params' do
        is_expected.to compile.and_raise_error(%r{invalid spec:})
      end
    end

    context 'with no params' do
      it do
        is_expected.to contain_concat__fragment('tcpd_allow_all_10_0_0_0_255_0_0_0').with(
          order: '100',
          target: '/etc/hosts.allow',
          content: "ALL:10.:ALLOW\n",
        )
      end
      context 'and hosts.deny enabled' do
        let(:pre_condition) do
          [
            'class { tcpwrappers: enable_hosts_deny => true }',
          ]
        end

        it do
          is_expected.to contain_concat__fragment('tcpd_allow_all_10_0_0_0_255_0_0_0').with(
            order: '100',
            target: '/etc/hosts.allow',
            content: "ALL:10.\n",
          )
        end
      end
    end

    context 'with a lot of params' do
      let(:params) do
        {
          except: '192.168.0.0/26',
          order: '111',
          daemon: 'sshd',
          client: ['10.0.0.0/255.255.0.0', '192.168.0.0/24'],
          comment: 'sshd tweaks',
        }
      end

      it do
        is_expected.to contain_concat__fragment('tcpd_allow_sshd_10_0_0_0_255_0_0_0').with(
          order: '111',
          target: '/etc/hosts.allow',
          content: "sshd:10.0. 192.168.0. EXCEPT 192.168.0.0/255.255.255.192:ALLOW\t# sshd tweaks\n",
        )
      end

      context 'and hosts.deny enabled' do
        let(:pre_condition) { ['class { tcpwrappers: enable_hosts_deny => true }'] }

        it do
          is_expected.to contain_concat__fragment('tcpd_allow_sshd_10_0_0_0_255_0_0_0').with(
            order: '111',
            target: '/etc/hosts.allow',
            content: "sshd:10.0. 192.168.0. EXCEPT 192.168.0.0/255.255.255.192\t# sshd tweaks\n",
          )
        end
      end
    end

    context 'with ensure => absent' do
      let(:params) { { ensure: 'absent' } }

      it { is_expected.to contain_tcpwrappers__entry('10.0.0.0/255.0.0.0').with_ensure('absent') }
    end

    context 'with IPv6 disabled' do
      let(:params) { { enable_ipv6: false } }

      it { is_expected.to contain_tcpwrappers__entry('10.0.0.0/255.0.0.0').with_enable_ipv6(false) }
    end

    context 'with simple hostname' do
      let(:title) { 'webserver' }

      it do
        is_expected.to contain_concat__fragment('tcpd_allow_all_webserver').with(
          order: '100',
          target: '/etc/hosts.allow',
          content: "ALL:webserver:ALLOW\n",
        )
      end
    end

    context 'with IPv6 address' do
      let(:title) { '::1' }

      it do
        is_expected.to contain_concat__fragment('tcpd_allow_all_1').with(
          order: '100',
          target: '/etc/hosts.allow',
          content: "ALL:[::1]:ALLOW\n",
        )
      end
    end

    context 'with keyword ALL (different title)' do
      let(:title) { 'ALL_EXTERNAL' }
      let(:params) { { client: 'ALL' } }

      it do
        is_expected.to contain_concat__fragment('tcpd_allow_all_all_external').with(
          order: '100',
          target: '/etc/hosts.allow',
          content: "ALL:ALL:ALLOW\n",
        )
      end
    end

    context 'with specific daemon' do
      let(:params) { { daemon: 'sshd' } }

      it do
        is_expected.to contain_concat__fragment('tcpd_allow_sshd_10_0_0_0_255_0_0_0').with(
          order: '100',
          target: '/etc/hosts.allow',
          content: "sshd:10.:ALLOW\n",
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on platform #{os}" do
      let(:facts) { facts }

      it_behaves_like 'a supported platform'
    end
  end
end
