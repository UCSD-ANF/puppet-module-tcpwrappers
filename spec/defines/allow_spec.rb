require 'spec_helper'

describe 'tcpwrappers::allow', type: 'define' do
  let(:title) { '10.0.0.0/255.0.0.0' }

  shared_examples_for 'basic allow functionality' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_tcpwrappers__entry(title).with_action('allow') }
    it { is_expected.to contain_tcpwrappers__entry(title).with_ensure('present') }
  end


  shared_examples_for 'a supported platform' do
    context 'with bad title' do
      let(:title) { '192.168/16' }

      it 'raises error due no params' do
        is_expected.to compile.and_raise_error(%r{invalid spec:})
      end
    end

    context 'with default parameters' do
      it_behaves_like 'basic allow functionality'
      
      it do
        is_expected.to contain_concat__fragment('tcpd_allow_all_10_0_0_0_255_0_0_0').with(
          order: '100',
          target: '/etc/hosts.allow',
          content: "ALL:10.:ALLOW\n",
        )
      end
    end

    context 'with hosts.deny enabled' do
      let(:pre_condition) { 'class { tcpwrappers: enable_hosts_deny => true }' }

      it_behaves_like 'basic allow functionality'
      
      it do
        is_expected.to contain_concat__fragment('tcpd_allow_all_10_0_0_0_255_0_0_0').with(
          order: '100',
          target: '/etc/hosts.allow',
          content: "ALL:10.\n",
        )
      end
    end

    context 'with comprehensive parameters' do
      let(:params) do
        {
          ensure: 'present',
          client: ['10.0.0.0/255.255.0.0', '192.168.0.0/24'],
          comment: 'sshd tweaks',
          daemon: 'sshd',
          enable_ipv6: true,
          except: '192.168.0.0/26',
          order: '111',
        }
      end

      it_behaves_like 'basic allow functionality'
      it { is_expected.to contain_tcpwrappers__entry(title).with_daemon('sshd') }
      it { is_expected.to contain_tcpwrappers__entry(title).with_order('111') }
      it { is_expected.to contain_tcpwrappers__entry(title).with_comment('sshd tweaks') }
      it { is_expected.to contain_tcpwrappers__entry(title).with_except('192.168.0.0/26') }
      it { is_expected.to contain_tcpwrappers__entry(title).with_enable_ipv6(true) }
      
      it do
        is_expected.to contain_concat__fragment('tcpd_allow_sshd_10_0_0_0_255_0_0_0').with(
          order: '111',
          target: '/etc/hosts.allow',
          content: "sshd:10.0. 192.168.0. EXCEPT 192.168.0.0/255.255.255.192:ALLOW\t# sshd tweaks\n",
        )
      end
    end

    context 'with ensure => absent' do
      let(:params) { { ensure: 'absent' } }

      it { is_expected.to contain_tcpwrappers__entry(title).with_ensure('absent') }
      it { is_expected.to contain_tcpwrappers__entry(title).with_action('allow') }
    end

    context 'with IPv6 disabled' do
      let(:params) { { enable_ipv6: false } }

      it { is_expected.to contain_tcpwrappers__entry(title).with_enable_ipv6(false) }
    end

    # Test different client types
    context 'with hostname client' do
      let(:title) { 'webserver' }

      it_behaves_like 'basic allow functionality'
      it do
        is_expected.to contain_concat__fragment('tcpd_allow_all_webserver').with(
          content: "ALL:webserver:ALLOW\n",
        )
      end
    end

    context 'with IPv6 client' do
      let(:title) { '::1' }

      it_behaves_like 'basic allow functionality'
      it do
        is_expected.to contain_concat__fragment('tcpd_allow_all_1').with(
          content: "ALL:[::1]:ALLOW\n",
        )
      end
    end

    context 'with IPv6 subnet' do
      let(:title) { '2001:db8::/32' }

      it_behaves_like 'basic allow functionality'
      it do
        is_expected.to contain_concat__fragment('tcpd_allow_all_2001_db8_32').with(
          content: "ALL:[2001:db8::]/32:ALLOW\n",
        )
      end
    end

    context 'with keyword client' do
      let(:title) { 'ALL_EXTERNAL' }
      let(:params) { { client: 'ALL' } }

      it_behaves_like 'basic allow functionality'
      it do
        is_expected.to contain_concat__fragment('tcpd_allow_all_all_external').with(
          content: "ALL:ALL:ALLOW\n",
        )
      end
    end

    context 'with LOCAL keyword' do
      let(:title) { 'LOCAL_HOSTS' }
      let(:params) { { client: 'LOCAL' } }

      it_behaves_like 'basic allow functionality'
      it do
        is_expected.to contain_concat__fragment('tcpd_allow_all_local_hosts').with(
          content: "ALL:LOCAL:ALLOW\n",
        )
      end
    end

    context 'with multiple clients' do
      let(:params) { { client: ['192.168.1.0/24', '10.0.0.0/8', 'localhost'] } }

      it_behaves_like 'basic allow functionality'
      it do
        is_expected.to contain_concat__fragment('tcpd_allow_all_10_0_0_0_255_0_0_0').with(
          content: "ALL:192.168.1. 10. localhost:ALLOW\n",
        )
      end
    end

    context 'with specific daemon and order' do
      let(:params) { { daemon: 'httpd', order: '050' } }

      it { is_expected.to contain_tcpwrappers__entry(title).with_daemon('httpd') }
      it { is_expected.to contain_tcpwrappers__entry(title).with_order('050') }
      it do
        is_expected.to contain_concat__fragment('tcpd_allow_httpd_10_0_0_0_255_0_0_0').with(
          order: '050',
          content: "httpd:10.:ALLOW\n",
        )
      end
    end

    context 'with comment only' do
      let(:params) { { comment: 'Allow admin networks' } }

      it { is_expected.to contain_tcpwrappers__entry(title).with_comment('Allow admin networks') }
      it do
        is_expected.to contain_concat__fragment('tcpd_allow_all_10_0_0_0_255_0_0_0').with(
          content: "ALL:10.:ALLOW\t# Allow admin networks\n",
        )
      end
    end

    context 'with except clause only' do
      let(:params) { { except: '10.0.0.100' } }

      it { is_expected.to contain_tcpwrappers__entry(title).with_except('10.0.0.100') }
      it do
        is_expected.to contain_concat__fragment('tcpd_allow_all_10_0_0_0_255_0_0_0').with(
          content: "ALL:10. EXCEPT 10.0.0.100:ALLOW\n",
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
