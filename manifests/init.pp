# Install nginx
#
class nginx(
  $ensure = present,
) {
  include nginx::config
  include homebrew

  case $ensure {
    present: {
      # Install our custom plist for nginx. This is one of the very few
      # pieces of setup that takes over priv. ports (80 in this case).

      file { '/Library/LaunchDaemons/dev.nginx.plist':
        content => template('nginx/dev.nginx.plist.erb'),
        group   => 'wheel',
        notify  => Service['dev.nginx'],
        owner   => 'root'
      }

      # Set up all the files and directories nginx expects. We go
      # nonstandard on this mofo to make things as clearly accessible as
      # possible under $BOXEN_HOME.

      file { [
        $nginx::config::configdir,
        $nginx::config::datadir,
        $nginx::config::logdir,
        $nginx::config::sitesdir
      ]:
        ensure => directory
      }

      file { $nginx::config::configfile:
        content => template('nginx/config/nginx/nginx.conf.erb'),
        notify  => Service['dev.nginx']
      }

      file { "${nginx::config::sitesdir}/default":
        content => template('nginx/config/nginx/default.erb'),
        notify  => Service['dev.nginx']
      }

      file { '/w/etc/nginx':
        ensure  => directory
      }

      file { "${nginx::config::configdir}/mime.types":
        notify  => Service['dev.nginx'],
        source  => 'puppet:///modules/nginx/config/nginx/mime.types'
      }

      # Set up a very friendly little default one-page site for when
      # people hit http://localhost.

      file { "${nginx::config::configdir}/public":
        ensure  => directory,
        recurse => true,
        source  => 'puppet:///modules/nginx/config/nginx/public'
      }

      homebrew::tap { 'homebrew/nginx': }

      package { 'gd':
        before => Package['nginx-full'],
      }

      # https://github.com/Homebrew/homebrew-nginx/blob/master/Formula/nginx-full.rb
      package { 'nginx-full':
        install_options => [
                            '--devel',
                            # core modules
                            '--with-passenger',     # Compile with support for Phusion Passenger module
                            #'--no-pool-nginx',     # Disable nginx-pool, valgrind detect memory issues
                            '--with-addition',      # HTTP Addition module
                            '--with-auth-req',      # HTTP Auth Request module
                            #'--with-debug',        # debug log
                            '--with-degredation',   # HTTP Degredation module
                            '--with-flv',           # FLV module
                            '--with-geoip',         # GeoIP module
                            '--with-google-perftools', # Google Performance tools module
                            '--with-gunzip',        # gunzip module
                            '--with-gzip-static',   # gunzip module
                            '--with-http2',         # HTTP/2 mmodule
                            '--with-image-filter',  # Image Filter module
                            '--with-mail',          # Mail module
                            '--with-mp4',           # MP4 module
                            '--with-pcre-jit',      # JIIT in PCRE
                            "--with-perl=${boxen::config::homebrewdir}/perl", # Perl module
                            '--with-random-index',  # Random Index module
                            '--with-realip',        # real IP module
                            '--with-secure-link',   # secure link module
                            '--with-status',        # stub status module
                            '--with-stream',        # TCP load balancing module
                            '--with-sub',           # HTTP Sub module
                            '--with-webdav',        # WebDAV module
                            '--with-xslt',          # XSLT module
                            # third_party_modules
                            '--with-mruby-module',  # MRuby module
                            '--with-lua',           # Lua mmodule
                            ],
        require         => Homebrew::Tap['homebrew/nginx'],
        notify          => Service['dev.nginx']
      }

      # Remove Homebrew's nginx config to avoid confusion.

      file { "${boxen::config::homebrewdir}/etc/nginx":
        ensure => link,
        target => "${boxen::config::configdir}/nginx"
      }

      service { 'dev.nginx':
        ensure  => running,
        require => Package['nginx-full']
      }
    }

    absent: {
      service { 'dev.nginx':
        ensure => stopped
      }

      file { '/Library/LaunchDaemons/dev.nginx.plist':
        ensure => absent
      }

      file { [
        $nginx::config::configdir,
        $nginx::config::datadir,
        $nginx::config::logdir,
        $nginx::config::sitesdir
      ]:
        ensure => absent
      }

      package { 'nginx-full':
        ensure => absent
      }
    }

    default: {
      fail('Nginx#ensure must be present or absent!')
    }
  }
}
