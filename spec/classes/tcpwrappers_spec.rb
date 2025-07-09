require 'spec_helper'

describe 'tcpwrappers', type: 'class' do
  shared_examples 'install disabled' do
    it { is_expected.not_to contain_package('tcpd') }
    it { is_expected.not_to contain_package('tcp_wrappers') }
  end

  shared_examples 'hosts.deny enabled' do
    it { is_expected.to contain_concat('/etc/hosts.deny') }
    it { is_expected.not_to contain_file('/etc/hosts.deny').with_ensure('absent') }
    it {
      is_expected.to contain_concat__fragment('tcpd_deny_all_all')\
        .with(target: '/etc/hosts.deny',
              content: "ALL:ALL\t# default deny everything\n")
    }
  end

  shared_examples_for 'hosts.deny is disabled' do
    it { is_expected.not_to contain_concat('/etc/hosts.deny') }
    it { is_expected.to contain_file('/etc/hosts.deny').with_ensure('absent') }
    it {
      is_expected.to contain_concat__fragment('tcpd_deny_all_all')\
        .with(target: '/etc/hosts.allow',
              content: "ALL:ALL:DENY\t# default deny everything\n")
    }
  end

  shared_examples_for 'all supported platforms' do
    it { is_expected.to contain_concat('/etc/hosts.allow') }
    it {
      is_expected.to contain_concat__fragment('tcpd_deny_all_all').with_order('999')
    }
    it {
      is_expected.to contain_concat__fragment('tcpd_allow_all_localhost')\
        .with(target: '/etc/hosts.allow',
              content: 'ALL:localhost localhost.localdomain localhost4 '   \
        'localhost4.localdomain4 localhost6 localhost6.localdomain6 ' \
        "127. [::1]:ALLOW\t# default allow localhost\n")
    }

    context 'IPv6 disabled' do
      let(:params) { { enable_ipv6: false } }

      it {
        is_expected.to contain_concat__fragment('tcpd_allow_all_localhost')\
          .with(target: '/etc/hosts.allow',
                content: 'ALL:localhost localhost.localdomain localhost4 '   \
             'localhost4.localdomain4 localhost6 localhost6.localdomain6 ' \
             "127.:ALLOW\t# default allow localhost\n")
      }
    end

    context 'Do not deny-by-default' do
      let(:params) { { deny_by_default: false } }

      it { is_expected.not_to contain_concat__fragment('tcpd_deny_all_all') }
    end

    context 'with hosts.deny enabled' do
      let(:params) { { enable_hosts_deny: true } }

      it_behaves_like 'hosts.deny enabled'
    end

    context 'with ensure => absent' do
      let(:params) { { ensure: 'absent' } }

      it { is_expected.to contain_concat('/etc/hosts.allow').with_ensure('absent') }
      it { is_expected.to contain_tcpwrappers__allow('localhost').with_ensure('absent') }
      it { is_expected.to contain_tcpwrappers__deny('ALL').with_ensure('absent') }
    end

    context 'with deny_by_default => false and ensure => absent' do
      let(:params) { { deny_by_default: false, ensure: 'absent' } }

      it { is_expected.to contain_concat('/etc/hosts.allow').with_ensure('absent') }
      it { is_expected.to contain_tcpwrappers__allow('localhost').with_ensure('absent') }
      it { is_expected.not_to contain_tcpwrappers__deny('ALL') }
    end

    context 'with IPv6 disabled' do
      let(:params) { { enable_ipv6: false } }

      it { is_expected.to contain_tcpwrappers__allow('localhost').with_enable_ipv6(false) }
      it { is_expected.to contain_tcpwrappers__deny('ALL').with_enable_ipv6(false) }
    end
  end

  shared_examples_for 'Debian' do
    describe 'Debian-specific behavior' do
      context 'with defaults' do
        it { is_expected.to contain_package('tcpd') }
        it_behaves_like 'hosts.deny is disabled'
      end
    end
    it_behaves_like 'all supported platforms'
  end

  shared_examples_for 'RedHat' do
    describe 'RedHat-specific behavior' do
      context 'with defaults' do
        it { is_expected.to contain_package('tcp_wrappers') }
        it_behaves_like 'hosts.deny is disabled'
      end
    end
    it_behaves_like 'all supported platforms'
  end

  shared_examples_for 'FreeBSD' do
    describe 'FreeBSD-specific behavior' do
      context 'with defaults' do
        it { is_expected.to contain_concat('/etc/hosts.allow').with_group('wheel') }
        it_behaves_like 'install disabled'
        it_behaves_like 'hosts.deny is disabled'
      end
    end
    it_behaves_like 'all supported platforms'
  end

  shared_examples_for 'other supported platform' do
    describe 'other platform specific behavior' do
      context 'with defaults' do
        it_behaves_like 'install disabled'
        it_behaves_like 'hosts.deny is disabled'
      end
    end
    it_behaves_like 'all supported platforms'
  end

  on_supported_os.each do |os, facts|
    context "on platform #{os}" do
      let(:facts) { facts }

      case facts[:osfamily]
      when 'Debian' then
        it_behaves_like 'Debian'

      when 'RedHat' then
        it_behaves_like 'RedHat'

      when 'FreeBSD' then
        it_behaves_like 'FreeBSD'

      else
        it_behaves_like 'other supported platform'

      end
    end
  end
end
