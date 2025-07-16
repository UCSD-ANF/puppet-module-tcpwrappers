require 'spec_helper'

describe 'tcpwrappers::deny', type: 'define' do
  let(:title) { '10.0.0.0/8' }

  shared_examples_for 'basic deny functionality' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_tcpwrappers__entry(title).with_action('deny') }
    it { is_expected.to contain_tcpwrappers__entry(title).with_ensure('present') }
  end


  shared_examples_for 'a supported platform' do
    context 'with bad title' do
      let(:title) { '10/8' }

      it 'raises error due no params' do
        is_expected.to raise_error(Puppet::Error, %r{invalid spec:})
      end
    end

    context 'with default parameters' do
      it_behaves_like 'basic deny functionality'
      
      it do
        is_expected.to contain_concat__fragment('tcpd_deny_all_10_0_0_0_8').with(
          order: '200',
          target: '/etc/hosts.allow',
          content: "ALL:10.:DENY\n",
        )
      end
    end

    context 'with hosts.deny enabled' do
      let(:pre_condition) { 'class { tcpwrappers: enable_hosts_deny => true }' }

      it_behaves_like 'basic deny functionality'
      
      it do
        is_expected.to contain_concat__fragment('tcpd_deny_all_10_0_0_0_8').with(
          order: '200',
          target: '/etc/hosts.deny',
          content: "ALL:10.\n",
        )
      end
    end

    context 'with comprehensive parameters' do
      let(:params) do
        {
          ensure: 'present',
          client: ['10.0.0.0/255.255.0.0', '192.168.0.0/24'],
          comment: 'sshd restrictions',
          daemon: 'sshd',
          enable_ipv6: true,
          except: '192.168.0.0/26',
          order: '111',
        }
      end

      it_behaves_like 'basic deny functionality'
      it { is_expected.to contain_tcpwrappers__entry(title).with_daemon('sshd') }
      it { is_expected.to contain_tcpwrappers__entry(title).with_order('111') }
      it { is_expected.to contain_tcpwrappers__entry(title).with_comment('sshd restrictions') }
      it { is_expected.to contain_tcpwrappers__entry(title).with_except('192.168.0.0/26') }
      it { is_expected.to contain_tcpwrappers__entry(title).with_enable_ipv6(true) }
      
      it do
        is_expected.to contain_concat__fragment('tcpd_deny_sshd_10_0_0_0_8').with(
          order: '111',
          target: '/etc/hosts.allow',
          content: "sshd:10.0. 192.168.0. EXCEPT 192.168.0.0/255.255.255.192:DENY\t# sshd restrictions\n",
        )
      end
    end

    context 'with ensure => absent' do
      let(:params) { { ensure: 'absent' } }

      it { is_expected.to contain_tcpwrappers__entry(title).with_ensure('absent') }
      it { is_expected.to contain_tcpwrappers__entry(title).with_action('deny') }
    end

    context 'with IPv6 disabled' do
      let(:params) { { enable_ipv6: false } }

      it { is_expected.to contain_tcpwrappers__entry(title).with_enable_ipv6(false) }
    end

    # Test different client types
    context 'with hostname client' do
      let(:title) { 'badhost' }

      it_behaves_like 'basic deny functionality'
      it do
        is_expected.to contain_concat__fragment('tcpd_deny_all_badhost').with(
          content: "ALL:badhost:DENY\n",
        )
      end
    end

    context 'with IPv6 client' do
      let(:title) { '::1' }

      it_behaves_like 'basic deny functionality'
      it do
        is_expected.to contain_concat__fragment('tcpd_deny_all_1').with(
          content: "ALL:[::1]:DENY\n",
        )
      end
    end

    context 'with IPv6 subnet' do
      let(:title) { '2001:db8::/32' }

      it_behaves_like 'basic deny functionality'
      it do
        is_expected.to contain_concat__fragment('tcpd_deny_all_2001_db8_32').with(
          content: "ALL:[2001:db8::]/32:DENY\n",
        )
      end
    end

    context 'with keyword client' do
      let(:title) { 'ALL_EXTERNAL' }
      let(:params) { { client: 'ALL' } }

      it_behaves_like 'basic deny functionality'
      it do
        is_expected.to contain_concat__fragment('tcpd_deny_all_all_external').with(
          content: "ALL:ALL:DENY\n",
        )
      end
    end

    context 'with PARANOID keyword' do
      let(:title) { 'PARANOID_HOSTS' }
      let(:params) { { client: 'PARANOID' } }

      it_behaves_like 'basic deny functionality'
      it do
        is_expected.to contain_concat__fragment('tcpd_deny_all_paranoid_hosts').with(
          content: "ALL:PARANOID:DENY\n",
        )
      end
    end

    context 'with multiple clients' do
      let(:params) { { client: ['192.168.1.0/24', '172.16.0.0/16', 'badhost.example.com'] } }

      it_behaves_like 'basic deny functionality'
      it do
        is_expected.to contain_concat__fragment('tcpd_deny_all_10_0_0_0_8').with(
          content: "ALL:192.168.1. 172.16. badhost.example.com:DENY\n",
        )
      end
    end

    context 'with specific daemon and high priority order' do
      let(:params) { { daemon: 'telnet', order: '050' } }

      it { is_expected.to contain_tcpwrappers__entry(title).with_daemon('telnet') }
      it { is_expected.to contain_tcpwrappers__entry(title).with_order('050') }
      it do
        is_expected.to contain_concat__fragment('tcpd_deny_telnet_10_0_0_0_8').with(
          order: '050',
          content: "telnet:10.:DENY\n",
        )
      end
    end

    context 'with comment only' do
      let(:params) { { comment: 'Block suspicious networks' } }

      it { is_expected.to contain_tcpwrappers__entry(title).with_comment('Block suspicious networks') }
      it do
        is_expected.to contain_concat__fragment('tcpd_deny_all_10_0_0_0_8').with(
          content: "ALL:10.:DENY\t# Block suspicious networks\n",
        )
      end
    end

    context 'with except clause only' do
      let(:params) { { except: '10.0.0.5' } }

      it { is_expected.to contain_tcpwrappers__entry(title).with_except('10.0.0.5') }
      it do
        is_expected.to contain_concat__fragment('tcpd_deny_all_10_0_0_0_8').with(
          content: "ALL:10. EXCEPT 10.0.0.5:DENY\n",
        )
      end
    end

    context 'with domain suffix' do
      let(:title) { 'domain_restriction' }
      let(:params) { { client: '.badcompany.com' } }

      it_behaves_like 'basic deny functionality'
      it do
        is_expected.to contain_concat__fragment('tcpd_deny_all_domain_restriction').with(
          content: "ALL:.badcompany.com:DENY\n",
        )
      end
    end

    context 'with file path client' do
      let(:title) { 'file_based_deny' }
      let(:params) { { client: '/etc/hosts.deny.custom' } }

      it_behaves_like 'basic deny functionality'
      it do
        is_expected.to contain_concat__fragment('tcpd_deny_all_file_based_deny').with(
          content: "ALL:/etc/hosts.deny.custom:DENY\n",
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
