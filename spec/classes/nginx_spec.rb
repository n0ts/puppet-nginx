require 'spec_helper'

describe 'nginx' do
  let(:facts) { default_test_facts }

  it do
    should contain_class('nginx::config')
    should contain_class('homebrew')

    should contain_file('/Library/LaunchDaemons/dev.nginx.plist').with({
      :group  => 'wheel',
      :notify => 'Service[dev.nginx]',
      :owner  => 'root'
    })

    should contain_file('/test/boxen/homebrew/etc/boxen/nginx').with_ensure('directory')
    should contain_file('/test/boxen/data/nginx').with_ensure('directory')
    should contain_file('/test/boxen/log/nginx').with_ensure('directory')
    should contain_file('/test/boxen/homebrew/etc/boxen/nginx/sites').
      with_ensure('directory')

    should contain_file('/test/boxen/homebrew/etc/boxen/nginx/nginx.conf').
      with_notify('Service[dev.nginx]')

    should contain_file('/test/boxen/homebrew/etc/boxen/nginx/mime.types').with({
      :notify => 'Service[dev.nginx]',
      :source => 'puppet:///modules/nginx/config/nginx/mime.types'
    })

    should contain_file('/test/boxen/homebrew/etc/boxen/nginx/public').with({
      :ensure  => 'directory',
      :recurse => true,
      :source  => 'puppet:///modules/nginx/config/nginx/public'
    })

    should contain_homebrew__tap('denji/nginx')

    should contain_package('nginx-full').with({
      :require => 'Homebrew::Tap[denji/nginx]',
      :notify  => 'Service[dev.nginx]'
    })

    should contain_file('/test/boxen/homebrew/etc/nginx').with({
      :ensure => 'link',
      :target => "/test/boxen/homebrew/etc/boxen/nginx",
    })

    should contain_service('dev.nginx').with({
      :ensure  => 'running',
      :require => 'Package[nginx-full]',
    })
  end

end
