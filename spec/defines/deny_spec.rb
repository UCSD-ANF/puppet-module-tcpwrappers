require 'spec_helper'

describe 'tcpwrappers::deny', type: 'define' do
  let(:title) { '10.0.0.0/8' }

  shared_examples_for 'a supported platform' do
    context 'with bad title' do
      let(:title) { '10/8' }

      it 'raises error due no params' do
        is_expected.to raise_error(Puppet::Error, %r{invalid spec:})
      end
    end

    context 'with no params' do
      it do
        is_expected.to contain_concat__fragment('tcpd_deny_all_10_0_0_0_8').with(
          order: '200',
          target: '/etc/hosts.allow',
          content: "ALL:10.:DENY\n",
        )
      end
      context 'and hosts.deny enabled' do
        let :pre_condition do
          [
            'class { tcpwrappers: enable_hosts_deny => true }',
          ]
        end

        it do
          is_expected.to contain_concat__fragment('tcpd_deny_all_10_0_0_0_8').with(
            order: '200',
            target: '/etc/hosts.deny',
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
        is_expected.to contain_concat__fragment('tcpd_deny_sshd_10_0_0_0_8').with(
          order: '111',
          target: '/etc/hosts.allow',
          content: "sshd:10.0. 192.168.0. EXCEPT 192.168.0.0/255.255.255.192:DENY\t# sshd tweaks\n",
        )
      end

      context 'and hosts.deny enabled' do
        let(:pre_condition) do
          [
            'class { tcpwrappers: enable_hosts_deny => true }',
          ]
        end

        it do
          is_expected.to contain_concat__fragment('tcpd_deny_sshd_10_0_0_0_8').with(
            order: '111',
            target: '/etc/hosts.deny',
            content: "sshd:10.0. 192.168.0. EXCEPT 192.168.0.0/255.255.255.192\t# sshd tweaks\n",
          )
        end
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
