class dmlite::gridftp (
  Integer[0,1] $detach = 1,
  Integer[0,1] $disable_usage_stats = 1,
  Stdlib::Unixpath $log_single = '/var/log/dpm-gsiftp/gridftp.log',
  Stdlib::Unixpath $log_transfer = '/var/log/dpm-gsiftp/dpm-gsiftp.log',
  String $log_level = 'ERROR,WARN,INFO',
  Stdlib::Port $port = 2811,
  Stdlib::Host $dpmhost = $::fqdn,
  Stdlib::Host $nshost = $::fqdn,
  String $user = $dmlite::params::user,
  String $group = $dmlite::params::group,
  Boolean $enable_hdfs = false,
  Integer[0,1] $data_node = 0,
  Optional[String] $remote_nodes = undef,
  Boolean $enable_dome_checksum = false,
  Boolean $legacy = true,
  String $dsi_package_name = 'dmlite-dpm-dsi'
) {
  File['/var/log/dpm-gsiftp'] -> Class[gridftp::config]
  Package[$dsi_package_name] -> Class[gridftp::config]
  Package[$dsi_package_name] -> File['/etc/sysconfig/dpm-gsiftp']
  Class['gridftp::config'] -> Exec['remove_globus-gridftp-server_init_management']
  Class[dmlite::gridftp] ~> Class['gridftp::service']

  if !$legacy {
    Class[dmlite::base::config] -> Class[dmlite::gridftp]
  }
  else {
    Class[lcgdm::base::config] -> Class[dmlite::gridftp]
  }
  if $enable_hdfs {
    include dmlite::plugins::hdfs::params
    $java_home = $dmlite::plugins::hdfs::params::java_home
  }
  
  #if gridftp redirection is enabled ( so remote_nodes is set to 1) configure epsv_ip
  case $remote_nodes {
    undef: {
      $epsv_ip = false
    }
    default: {
      $epsv_ip = true
    }
  }
  package{$dsi_package_name: ensure => present}

  file {
    '/etc/sysconfig/dpm-gsiftp':
      ensure  => present,
      owner   => $user,
      group   => $group,
      content => template('dmlite/gridftp/sysconfig.erb')
  }

  # gridftp configuration
  file {
    '/var/log/dpm-gsiftp':
      ensure => directory,
      owner  => $user,
      group  => $group,
  }
  class{'gridftp::install':}
  class{'gridftp::config':
    user                => $user,
    group               => $group,
    auth_level          => 0,
    detach              => $detach,
    disable_usage_stats => $disable_usage_stats,
    load_dsi_module     => 'dmlite',
    log_single          => $log_single,
    log_transfer        => $log_transfer,
    log_level           => $log_level,
    login_msg           => 'Disk Pool Manager (dmlite)',
    port                => $port,
    service             => 'dpm-gsiftp',
    sysconfigfile       => '/etc/sysconfig/globus',
    thread_model        => 'pthread',
    data_node           => $data_node,
    remote_nodes        => $remote_nodes,
    epsv_ip             => $epsv_ip,
  }
  exec{'remove_globus-gridftp-server_init_management':
    command => '/sbin/chkconfig globus-gridftp-server off',
    onlyif  => '/sbin/chkconfig globus-gridftp-server'
  }

  include dmlite::gaiconfig

  class{'gridftp::service':
    service                 => 'dpm-gsiftp',
    certificate             => "/etc/grid-security/${dmlite::gridftp::user}/dpmcert.pem",
    key                     => "/etc/grid-security/${dmlite::gridftp::user}/dpmkey.pem",
    restart_on_cert_renewal => true
  }
}

