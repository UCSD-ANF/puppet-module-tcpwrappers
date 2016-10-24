require 'spec_helper'

describe 'tcpwrappers', :type=>'class' do

	platforms = [
    { :operatingsystem => 'Debian',
      :osfamily        => 'Debian',
    },
    { :operatingsystem => 'CentOS',
      :osfamily        => 'RedHat',
    },
    { :operatingsystem => 'Darwin',
      :osfamily        => 'Darwin',
    },
    { :operatingsystem => 'Solaris',
      :osfamily        => 'Solaris',
    },
    { :operatingsystem => 'FreeBSD',
      :osfamily        => 'FreeBSD',
    },
  ]
  shared_context 'install disabled' do
    it { should_not contain_package('tcpd') }
    it { should_not contain_package('tcp_wrappers') }
  end

  shared_context 'hosts.deny enabled' do
    it { should contain_concat('/etc/hosts.deny') }
    it { should_not contain_file('/etc/hosts.deny').with_ensure('absent') }
    it { should contain_concat__fragment('tcpd_deny_all_all').with({
      :target  => '/etc/hosts.deny',
      :content => "ALL:ALL\t# default deny everything\n"
    }) }
  end

  shared_context 'hosts.deny disabled' do
    it { should_not contain_concat('/etc/hosts.deny') }
    it { should contain_file('/etc/hosts.deny').with_ensure('absent') }
    it { should contain_concat__fragment('tcpd_deny_all_all').with({
      :target  => '/etc/hosts.allow',
      :content => "ALL:ALL:DENY\t# default deny everything\n"
    }) }
  end

	platforms.each do |platform|
		describe "Running on #{platform[:operatingsystem]}" do
      let(:facts) do {
        :operatingsystem => platform[:operatingsystem],
        :osfamily        => platform[:osfamily],
        :concat_basedir  => '/foo/bar/baz',
      } end
			it { should contain_concat('/etc/hosts.allow') }
			it { should contain_concat__fragment('tcpd_deny_all_all'
                                          ).with_order('999') }
      it { should contain_concat__fragment('tcpd_allow_all_localhost').with({
        :target  => '/etc/hosts.allow',
        :content => 'ALL:localhost localhost.localdomain localhost4 '   +
          'localhost4.localdomain4 localhost6 localhost6.localdomain6 ' +
          "127. [::1]:ALLOW\t# default allow localhost\n",
      }) }

      case platform[:osfamily]
      when 'Debian' then
        it { should contain_package('tcpd') }
        it_behaves_like 'hosts.deny disabled'
      when 'RedHat' then
        it { should contain_package('tcp_wrappers') }
        it_behaves_like 'hosts.deny disabled'
      when 'FreeBSD' then
        it { should contain_concat('/etc/hosts.allow').with_group('wheel') }
        it_behaves_like 'install disabled'
        it_behaves_like 'hosts.deny disabled'
      else
        it_behaves_like 'install disabled'
        it_behaves_like 'hosts.deny disabled'
      end

			context 'IPv6 disabled' do
        let(:params) do { :enable_ipv6 => false } end
        it { should contain_concat__fragment('tcpd_allow_all_localhost').with({
          :target  => '/etc/hosts.allow',
          :content => 'ALL:localhost localhost.localdomain localhost4 '   +
            'localhost4.localdomain4 localhost6 localhost6.localdomain6 ' +
            "127.:ALLOW\t# default allow localhost\n",
        }) }
      end

			context 'Do not deny-by-default' do
        let(:params) do { :deny_by_default => false } end
          it { should_not contain_concat__fragment('tcpd_deny_all_all') }
			end

			context 'with hosts.deny enabled' do
        let :params do { :enable_hosts_deny => true } end
        it_behaves_like 'hosts.deny enabled'
      end
		end
	end
end
