class dmlite::dav::config (
  $dmlite_conf        = $dmlite::dav::dmlite_conf,
  $dmlite_disk_conf   = $dmlite::dav::dmlite_disk_conf,
  $ns_type            = $dmlite::dav::ns_type,
  $ns_prefix          = $dmlite::dav::ns_prefix,
  $disk_prefix        = $dmlite::dav::disk_prefix,
  $ns_flags           = $dmlite::dav::ns_flags,
  $ns_anon            = $dmlite::dav::ns_anon,
  $ns_max_replicas    = $dmlite::dav::ns_max_replicas,
  $ns_secure_redirect = $dmlite::dav::ns_secure_redirect,
  $ns_trusted_dns     = $dmlite::dav::ns_trusted_dns,
  $ns_macaroon_secret = $dmlite::dav::ns_macaroon_secret,
  $disk_flags         = $dmlite::dav::disk_flags,
  $disk_anon          = $dmlite::dav::disk_anon,
  $ssl_cert           = $dmlite::dav::ssl_cert,
  $ssl_key            = $dmlite::dav::ssl_key,
  $ssl_capath         = $dmlite::dav::ssl_capath,
  $ssl_options        = $dmlite::dav::ssl_options,
  $ssl_ciphersuite    = $dmlite::dav::ssl_ciphersuite,
  $log_error          = $dmlite::dav::log_error,
  $log_transfer       = $dmlite::dav::log_transfer,
  $log_level          = $dmlite::dav::log_level,
  $user               = $dmlite::dav::user,
  $group              = $dmlite::dav::group,
  $coredump_dir       = $dmlite::dav::coredump_dir,
  $ulimit             = $dmlite::dav::ulimit,
  $enable_ns          = $dmlite::dav::enable_ns,
  $enable_disk        = $dmlite::dav::enable_disk,
  $enable_https       = $dmlite::dav::enable_https,
  $enable_http        = $dmlite::dav::enable_http,
  $enable_keep_alive  = $dmlite::dav::enable_keep_alive,
  $mpm_model          = $dmlite::dav::mpm_model,
  $enable_hdfs        = $dmlite::dav::enable_hdfs,
  $libdir             = $dmlite::dav::libdir,
  $dav_http_port      = $dmlite::dav::dav_http_port,
  $dav_https_port     = $dmlite::dav::dav_https_port,
  $enable_srr_cgi     = $dmlite::dav::enable_srr_cgi,
  $enable_ns_oidc               = $dmlite::dav::enable_ns_oidc,
  $ns_oidc_scope                = $dmlite::dav::ns_oidc_scope,
  $ns_oidc_metadataurl          = $dmlite::dav::ns_oidc_metadataurl,
  $ns_oidc_clientid             = $dmlite::dav::ns_oidc_clientid,
  $ns_oidc_clientsecret         = $dmlite::dav::ns_oidc_clientsecret,
  $ns_oidc_passphrase           = $dmlite::dav::ns_oidc_passphrase,
  $ns_oidc_redirecturi          = $dmlite::dav::ns_oidc_redirecturi,
  $ns_oidc_auth_verify_jwks_uri = $dmlite::dav::ns_oidc_auth_verify_jwks_uri,
) {

  case $enable_hdfs {
    true:{
      $dav_template = 'dmlite/dav/zlcgdm-dav_hdfs.conf'
    }
    default: {
      $dav_template = 'dmlite/dav/zlcgdm-dav.conf'
    }
  }

  Class[dmlite::dav::install] -> Class[dmlite::dav::config]

  # some installations don't have complete data types enabled by default, use
  # str2bool to catch both cases
  if(str2bool($::selinux) != false) {
    selboolean{'httpd_can_network_connect': value => on, persistent => true }
    selboolean{'httpd_execmem': value => on, persistent => true }
  }

  if $enable_hdfs {
    include dmlite::plugins::hdfs::params
    $java_home= $dmlite::plugins::hdfs::params::java_home
    file {
      '/etc/sysconfig/httpd':
        ensure  => present,
        owner   => $user,
        group   => $group,
        content => template('dmlite/dav/sysconfig.erb'),
        notify  => Class[dmlite::dav::service]
    }
  }

  #enable cors
  $domain_string = regsubst($::domain, '\.', '\\.', 'G')
  file {
    '/etc/httpd/conf.d/cross-domain.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      content => template('dmlite/dav/cross-domain.conf.erb'),
      notify  => Class[dmlite::dav::service]
  }
  #enable mpm_conf
  file {
    '/etc/httpd/conf.d/mpm_event.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      content => template('dmlite/dav/mpm_event.conf'),
      notify  => Class[dmlite::dav::service]
  }

  file {
    '/etc/httpd/conf.d/ssl.conf':
      ensure  => present,
      content => "# content cleared by DPM puppet configuration\n# (file must exist to prevent default config revival during upgrades)\n";
    '/etc/httpd/conf.d/zgridsite.conf':
      ensure  => present,
      content => "# content cleared by DPM puppet configuration\n# (file must exist to prevent default config revival during upgrades)\n";
    '/etc/httpd/conf.d/zlcgdm-dav.conf':
      ensure  => present,
      content => template($dav_template);
  }

  # wrap default php configuration file content in a block
  # used conditionally only with prefork apache configuration
  exec {
    'dmlite_dont_try_to_configure_php_without_prefork':
      command => "sed -i '1s/^/<IfModule prefork.c>\\n/;\$ a </IfModule>' /etc/httpd/conf.d/php.conf",
      path    => '/bin:/usr/bin',
      unless  => [ 'test ! -s /etc/httpd/conf.d/php.conf', "grep -q '<IfModule prefork.c>' /etc/httpd/conf.d/php.conf 2> /dev/null" ];
  }

  #added proxycache folder

  file {
    '/var/www/proxycache':
      ensure => directory,
      owner  => $user,
      group  => $group,
      notify => Class[dmlite::dav::service]
  }

  # We need some additional tweaks to the httpd.conf.
  # Probably goes away if we start using a puppet module for apache.
  file_line {
    'no apache mod_dav':
      ensure => absent,
      line   => 'LoadModule dav_module modules/mod_dav.so',
      path   => '/etc/httpd/conf/httpd.conf';
    'no apache mod_dav_fs':
      ensure => absent,
      line   => 'LoadModule dav_fs_module modules/mod_dav_fs.so',
      path   => '/etc/httpd/conf/httpd.conf';
    'apache user':
      ensure => present,
      match  => '^User .*',
      line   => "User ${user}",
      path   => '/etc/httpd/conf/httpd.conf';
    'apache group':
      ensure => present,
      match  => '^Group .*',
      line   => "Group ${group}",
      path   => '/etc/httpd/conf/httpd.conf';
  }
  if $coredump_dir {
    file_line {'apache coredump':
      ensure => present,
      line   => "CoreDumpDirectory ${coredump_dir}",
      path   => '/etc/httpd/conf/httpd.conf'
    }
  }

  if $enable_keep_alive {
  file_line { 'apache keepalive':
      ensure => present,
      line   => 'KeepAlive On',
      path   => '/etc/httpd/conf/httpd.conf',
      match  => '^KeepAlive .*'
    }
  }

  if versioncmp($facts['os']['release']['major'], '8') < 0 {
    file_line{'mpm model':
      ensure => present,
      path   => '/etc/sysconfig/httpd',
      line   => "HTTPD=${mpm_model}",
      match  => '^#?HTTPD=/.*'
    }
  }

  if $ulimit {
    file_line {'apache ulimit':
      ensure => present,
      line   => "ulimit ${ulimit}",
      path   => '/etc/sysconfig/httpd'
    }
  }
  #centOS7 changes
  if versioncmp($facts['os']['release']['major'], '7') >= 0 {
    file {
      '/etc/httpd/conf.modules.d/00-dav.conf':
        ensure  => present,
        content => ''; # empty content, so an upgrade doesn't overwrite it
    }
    file_line { 'mpm event':
      ensure => present,
      line   => 'LoadModule mpm_event_module modules/mod_mpm_event.so',
      path   => '/etc/httpd/conf.modules.d/00-mpm.conf',
      match  => '^#?LoadModule mpm_event_module modules/mod_mpm_event.so'
    }
    file_line { 'mpm prefork':
      ensure => absent,
      line   => 'LoadModule mpm_prefork_module modules/mod_mpm_prefork.so',
      path   => '/etc/httpd/conf.modules.d/00-mpm.conf',
    }
  }
}
