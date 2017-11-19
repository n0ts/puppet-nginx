# Install nginx
#
class nginx(
  $ensure = present,
) inherits nginx::config {
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
        notify => Service['dev.nginx'],
        source => 'puppet:///modules/nginx/config/nginx/mime.types'
      }

      # Set up a very friendly little default one-page site for when
      # people hit http://localhost.
      file { "${nginx::config::configdir}/public":
        ensure  => directory,
        recurse => true,
        source  => 'puppet:///modules/nginx/config/nginx/public'
      }

      homebrew::tap { 'homebrew/nginx': }

      package { [ 'gd', 'gperftools' ]:
        before => Package['nginx-full'],
      }

      # https://github.com/Homebrew/homebrew-nginx/blob/master/Formula/nginx-full.rb
      # nginx-full install default module option: --with-http_ssl_module --with-pcre --with-ipv6
      package { 'nginx-full':
        install_options => [
                            '--devel',
                            # core modules
                            '--with-addition',                   # HTTP Addition support
                            '--with-auth-req',                   # HTTP Auth Request support
                            ##'--with-debug',                      # debug log
                            '--with-degredation',                # HTTP Degredation support
                            '--with-flv',                        # FLV support
                            '--with-geoip',                      # HTTP GeoIP support
                            '--with-google-perftools',           # Google Performance Tools support
                            '--with-gunzip',                     # Gunzip support
                            '--with-gzip-static',                # Gzip static support
                            '--with-http2',                      # HTTP/2 support
                            '--with-image-filter',               # Image Filter support
                            '--with-mail',                       # Mail support
                            '--with-mail-ssl',                   # Mail SSL/TLS support
                            '--with-mp4',                        # MP4 support
                            ##'--with-no-pool-nginx',              # without nginx-pool (valgrind debug memory)
                            '--with-passenger',                  # Phusion Passenger support
                            '--with-pcre-jit',                   # JIT in PCRE
                            ##'--with-perl',                       # Perl support - compile error
                            '--with-random-index',               # Random Index support
                            '--with-realip',                     # Real IP support
                            '--with-secure-link',                # Secure Link support
                            '--with-slice',                      # Slice support
                            '--with-status',                     # Stub status support
                            '--with-stream',                     # TCP/UDP proxy support
                            '--with-stream-ssl',                 # Stream SSL/TLS support
                            '--with-stream-ssl-preread',         # Stream with terminating SSL/TLS support
                            '--with-stream-geoip',               # Stream GeoIP support
                            '--with-stream-realip',              # Stream RealIP support
                            '--with-sub',                        # HTTP Sub support
                            '--with-webdav',                     # WebDAV support
                            '--with-xslt',                       # XSLT support
                            # third party modules
                            '--with-accept-language-module',     # Accept Language support
                            ##'--with-accesskey-module',           # HTTP Access Key support
                            ##'--with-ajp-module',                 # AJP-protocol support
                            ##'--with-anti-ddos-module',           # Anti-DOS support
                            ##'--with-array-var-module',           # Array Var support
                            '--with-auth-digest-module',         # Auth Digest support
                            ##'--with-auth-ldap-module',           # Auth LDAP support
                            ##'--with-auth-pam-module',            # Auth PAM support
                            ##'--with-auto-keepalive-module',      # Auto Disable Keepalive support
                            '--with-autols-module',              # Flexible Auto Index support
                            ##'--with-cache-purge-module',         # Cache Pruge support
                            ##'--with-captcha-module',             # Capcha support - required the ImageMagick library
                            ##'--with-counter-zone-module',        # Realtime Counter Zone support
                            ##'--with-ctpp2-module',               # CT++ support
                            '--with-dav-ext-module',             # HTTP WebDav Extended support
                            '--with-dosdetector-module',         # Detecting DoS attacks support
                            '--with-echo-module',                # Echo support
                            '--with-eval-module',                # Eval support
                            ##'--with-extended-status-module',     # Extended Status support
                            #### patch error:
                            #### Failure while executing:
                            #### /usr/bin/patch -g 0 -f -p1 -i
                            ####    nginx-full--patch-20171017-74250-7diioa/extended_status-1.10.1.patch
                            ##'--with-fancyindex-module',          # Fancy Index support
                            '--with-geoip2-module',              # GeoIP2 support
                            ##'--with-headers-more-module',        # Headers More support
                            ##'--with-healthcheck-module',         # Healthcheck support - compile error https://github.com/Homebrew/homebrew-nginx/issues/263
                            ##'--with-http-accounting-module',     # HTTP Accounting support
                            ##'--with-http-flood-detector-module', # Var Flood-Threshold support
                            ##'--with-http-remote-passwd-module',  # Remote Basic Auth Password support
                            '--with-log-if-module',              # Log-if support
                            '--with-lua-module',                 # LUA support
                            ##'--with-mod-zip-module',             # HTTP Zip support - compile error
                            ##'--with-mogilefs-module',            # HTTP MogileFS support
                            '--with-mp4-h264-module',            # HTTP MP4/H264 support
                            '--with-mruby-module',               # MRuby support
                            ##'--with-naxsi-module',               # Naxsi support
                            ##'--with-nchan-module',               # Nchan support
                            ##'--with-notice-module',              # HTTP Notice support
                            ##'--with-php-session-module',         # Parse PHP Sessions support
                            ##'--with-tarantool-module',           # Trantool upstream support
                            ##'--with-push-stream-module',         # HTTP Push Stream support
                            ##'--with-realtime-req-module',        # Realtime Request support
                            ##'--with-redis-module',               # Redis support
                            ##'--with-redis2-module',              # Redis2 support
                            ##'--with-rtmp-module',                # RTMP support
                            ##'--with-set-misc-module',            # Set Misc support
                            ##'--with-small-light-module',         # Small Light support *requires imagemagick@6
                            ##'--with-subs-filter-module',         # Substitutions support
                            ##'--with-tcp-proxy-module',           # TCP Proxy support
                            ##'--with-txid-module',                # Sortable Unique ID support
                            ##'--with-unzip-module',               # UnZip support
                            ##'--with-upload-module',              # Upload support - compile error https://github.com/Homebrew/homebrew-nginx/issues/304
                            ##'--with-upload-progress-module',     # Upload Progress support
                            ##'--with-upstream-order-module',      # Order Upstream support
                            ##'--with-ustats-module',              # Upstream Statistics (HAProxy style) support
                            ##'--with-var-req-speed-module',       # Var Request-Speed support
                            ##'--with-vod-module',                 # VOD on-the-fly MP4 Repackager support
                            ##'--with-websockify-module'.          # Websockify support
                            ##'--with-xsltproc-module'.            # XSLT Transformations support
                            # for MRuby module https://github.com/Homebrew/homebrew-nginx/issues/312
                            '--no-sandbox',
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
        ensure => absent,
        force  => true,
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
