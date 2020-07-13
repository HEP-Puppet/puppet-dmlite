class dmlite::xrootd (
  Array[Enum['head', 'disk']] $nodetype = ['head', 'disk'], # head, disk
  String $domain,
  Stdlib::Unixpath $dmlite_conf = '/etc/dmlite.conf',
  Stdlib::Host $dpmhost = $::fqdn,
  Stdlib::Host $nshost = $::fqdn,
  String $ns_basepath = 'dpm',
  Boolean $xrootd_use_voms = true,
  Boolean $xrootd_use_delegation = false,
  Optional[String] $xrootd_tpc_options = '',
  Optional[String] $xrootd_sec_level = undef,
  Optional[String] $xrootd_async = undef,
  Optional[String] $xrootd_monitor = undef,
  Boolean $xrootd_jemalloc = true,
  String $jemalloc_package = 'jemalloc',
  Optional[String] $xrd_timeout = undef,
  Optional[String] $xrd_report = undef,
  Boolean $xrd_dpmclassic = false,
  Boolean $dpm_xrootd_debug = false,
  String $dpm_xrootd_sharedkey = '',
  Stdlib::Port $dpm_xrootd_serverport = 1095,
  Stdlib::Host $dpm_mmreqhost = 'localhost',
  Optional[String] $site_name = undef,
  Boolean $alice_token = false,
  Optional[Stdlib::Unixpath] $alice_token_conf = undef,
  Optional[String] $alice_token_libname = undef,
  Optional[String] $alice_token_principal = undef,
  Optional[String] $alice_fqans = undef,
  Hash $dpm_xrootd_fedredirs = {},
  String $log_style_param = '-k fifo', #'-k fifo' for xrootd4
  String $vomsxrd_package = 'vomsxrd',
  Boolean $enable_hdfs = false,
  String $lcgdm_user = 'dpmmgr',
  Boolean $legacy = true,
  Boolean $dpm_enable_dome = false,
  String $dpm_xrdhttp_secret_key = '',
  String $after_conf_head = 'network-online.target mariadb.service',
  String $after_conf_disk = 'network-online.target',
  String $runtime_dir = 'dpmxrootd',
  Boolean $xrd_checksum_enabled = false,
  String $xrd_checksum = 'max 100 adler32 md5 crc32',
  String $dpm_xrd_packagename = 'dmlite-dpm-xrootd',
  String $dpm_xrdhttp_cipherlist = 'HIGH'
) {

  Dmlite::Xrootd::Create_config <| |> ~> Class[xrootd::service]
  Xrootd::Create_sysconfig <| |> ~> Class[xrootd::service]
  Exec['delete .xrootd.log files'] ~> Class[xrootd::service]
  Exec['delete .xrootd.log files'] -> Xrootd::Create_sysconfig <| |>
  Class[dmlite::xrootd] ~> Class['xrootd::service']
  if $legacy {
    Class[lcgdm::base::config] -> Class[dmlite::xrootd]
  } else {
    Class[dmlite::base::config] -> Class[dmlite::xrootd]
  }
  package {$dpm_xrd_packagename:
    ensure => present
  }

  $domainpath = "/${ns_basepath}/${domain}"

  include xrootd::config

  if $enable_hdfs {
    include dmlite::plugins::hdfs::params
    $java_home= $dmlite::plugins::hdfs::params::java_home
  } else {
    $java_home= undef
  }

  $sec_protocol_local = "/usr/${xrootd::config::xrdlibdir} unix"

  if $xrootd_use_voms == false and $xrd_dpmclassic == false {
    $dpm_listvoms = true
  }
  else {
    $dpm_listvoms = false
  }
  if $xrootd_use_voms == true and $xrd_dpmclassic == false {
    package{$vomsxrd_package:
      ensure => present
    }
  }


  #add possibility to disable xrd checksum
  if $xrd_checksum_enabled {
    $_xrd_checksum = $xrd_checksum
    $_xrd_ofsckslib = '= libXrdDPMCks.so.3'
    $_xrd_ofsosslib = '+cksio libXrdDPMOss.so.3'
  } else {
    $_xrd_checksum = undef
    $_xrd_ofsckslib = undef
    $_xrd_ofsosslib = 'libXrdDPMOss.so.3'
  }

  if member($nodetype, 'disk') {

    if $xrootd_use_voms {
      if $xrootd_use_delegation {
        $sec_protocol_disk = "/usr/${xrootd::config::xrdlibdir} gsi -dlgpxy:1 -exppxy:=creds -crl:3 -key:/etc/grid-security/${lcgdm_user}/dpmkey.pem -cert:/etc/grid-security/${lcgdm_user}/dpmcert.pem -md:sha256:sha1 -ca:2 -gmapopt:10 -vomsfun:/usr/${xrootd::config::xrdlibdir}/libXrdSecgsiVOMS.so"
      } else {
        $sec_protocol_disk = "/usr/${xrootd::config::xrdlibdir} gsi -crl:3 -key:/etc/grid-security/${lcgdm_user}/dpmkey.pem -cert:/etc/grid-security/${lcgdm_user}/dpmcert.pem -md:sha256:sha1 -ca:2 -gmapopt:10 -vomsfun:/usr/${xrootd::config::xrdlibdir}/libXrdSecgsiVOMS.so"
      }
    } else {
      $sec_protocol_disk = "/usr/${xrootd::config::xrdlibdir} gsi -crl:3 -key:/etc/grid-security/${lcgdm_user}/dpmkey.pem -cert:/etc/grid-security/${lcgdm_user}/dpmcert.pem -md:sha256:sha1 -ca:2 -gmapopt:10 -vomsat:0"
    }

    if $xrd_dpmclassic == false {
      if $xrootd_use_delegation == false {
        $ofs_tpc = "${xrootd_tpc_options} pgm /usr/bin/xrdcp --server"
      } else {
        $ofs_tpc = "${xrootd_tpc_options} oids fcreds gsi =X509_USER_PROXY pgm /usr/bin/xrdcp --server"
      }
    }

    $xrootd_instances_options_disk = {
      'disk' => "-l /var/log/xrootd/xrootd.log -c /etc/xrootd/xrootd-dpmdisk.cfg ${log_style_param}"
    }

    dmlite::xrootd::create_config{'/etc/xrootd/xrootd-dpmdisk.cfg':
      dmlite_conf            => $dmlite_conf,
      dpm_host               => $dpmhost,
      all_adminpath          => '/var/spool/xrootd',
      all_pidpath            => '/var/run/xrootd',
      all_sitename           => $site_name,
      xrd_allrole            => 'server',
      xrootd_seclib          => 'libXrdSec.so',
      xrootd_export          => [ '/' ],
      xrootd_async           => $xrootd_async,
      xrootd_monitor         => $xrootd_monitor,
      ofs_authlib            => 'libXrdDPMDiskAcc.so.3',
      ofs_authorize          => true,
      xrd_ofsosslib          => $_xrd_ofsosslib,
      xrd_ofsckslib          => $_xrd_ofsckslib,
      xrootd_chksum          => $_xrd_checksum,
      xrd_port               => $dpm_xrootd_serverport,
      xrd_network            => 'nodnr',
      xrd_timeout            => $xrd_timeout,
      xrd_report             => $xrd_report,
      xrd_debug              => $dpm_xrootd_debug,
      ofs_tpc                => $ofs_tpc,
      sec_protocol           => [ $sec_protocol_disk, $sec_protocol_local ],
      sec_level              => $xrootd_sec_level,
      dpm_listvoms           => $dpm_listvoms,
      use_dmlite_io          => $enable_hdfs,
      dpm_enable_dome        => $dpm_enable_dome,
      dpm_xrdhttp_secret_key => $dpm_xrdhttp_secret_key,
      dpm_dome_conf_file     => '/etc/domedisk.conf',
      dpm_xrdhttp_cipherlist => $dpm_xrdhttp_cipherlist
    }
  } else {
    $xrootd_instances_options_disk = {}
  }

  if member($nodetype, 'head') {

    if $xrootd_use_voms {
      $sec_protocol_redir = "/usr/${xrootd::config::xrdlibdir} gsi -crl:3 -key:/etc/grid-security/${lcgdm_user}/dpmkey.pem -cert:/etc/grid-security/${lcgdm_user}/dpmcert.pem -md:sha256:sha1 -ca:2 -gmapopt:10 -vomsfun:/usr/${xrootd::config::xrdlibdir}/libXrdSecgsiVOMS.so"
    } else {
      $sec_protocol_redir = "/usr/${xrootd::config::xrdlibdir} gsi -crl:3 -key:/etc/grid-security/${lcgdm_user}/dpmkey.pem -cert:/etc/grid-security/${lcgdm_user}/dpmcert.pem -md:sha256:sha1 -ca:2 -gmapopt:10 -vomsat:0"
    }

    $xrootd_instances_options_redir = {
      'redir' => "-l /var/log/xrootd/xrootd.log -c /etc/xrootd/xrootd-dpmredir.cfg ${log_style_param}"
    }

    $ofs_authlib = 'libXrdDPMRedirAcc.so.3'

    dmlite::xrootd::create_config{'/etc/xrootd/xrootd-dpmredir.cfg':
      dmlite_conf            => $dmlite_conf,
      dpm_host               => $dpmhost,
      all_adminpath          => '/var/spool/xrootd',
      all_pidpath            => '/var/run/xrootd',
      all_sitename           => $site_name,
      xrd_allrole            => 'manager',
      xrootd_seclib          => 'libXrdSec.so',
      xrootd_export          => [ '/' ],
      xrootd_monitor         => $xrootd_monitor,
      ofs_authlib            => $ofs_authlib,
      ofs_authorize          => true,
      xrd_ofsosslib          => $_xrd_ofsosslib,
      xrd_ofsckslib          => $_xrd_ofsckslib,
      xrootd_chksum          => $_xrd_checksum,
      ofs_cmslib             => 'libXrdDPMFinder.so.3',
      ofs_forward            => 'all',
      xrd_network            => 'nodnr',
      xrd_timeout            => $xrd_timeout,
      xrd_report             => $xrd_report,
      xrd_debug              => $dpm_xrootd_debug,
      sec_protocol           => [ $sec_protocol_redir, $sec_protocol_local ],
      sec_level              => $xrootd_sec_level,
      dpm_listvoms           => $dpm_listvoms,
      dpm_mmreqhost          => $dpm_mmreqhost,
      dpm_defaultprefix      => "${domainpath}/home",
      dpm_xrootd_serverport  => $dpm_xrootd_serverport,
      domainpath             => $domainpath,
      alice_token            => $alice_token,
      alice_token_conf       => $alice_token_conf,
      alice_token_principal  => $alice_token_principal,
      alice_token_libname    => $alice_token_libname,
      alice_fqans            => $alice_fqans,
      dpm_xrootd_fedredirs   => $dpm_xrootd_fedredirs,
      dpm_enable_dome        => $dpm_enable_dome,
      dpm_xrdhttp_secret_key => $dpm_xrdhttp_secret_key,
      dpm_dome_conf_file     => '/etc/domehead.conf',
      dpm_xrdhttp_cipherlist => $dpm_xrdhttp_cipherlist
    }
    $l = size($::fqdn)
    if $l > 16 {
      $cms_cidtag = regsubst($::fqdn, '^(.{16})(.*)', '\1')
    } else {
      $cms_cidtag = $::fqdn
    }

    $oss_statlib = '-2 libXrdDPMStatInfo.so.3'

    $federation_defaults = {
      dmlite_conf           => $dmlite_conf,
      dpm_host              => $dpmhost,
      all_adminpath         => '/var/spool/xrootd',
      all_pidpath           => '/var/run/xrootd',
      all_sitename          => $site_name,
      cms_cidtag            => $cms_cidtag,
      xrd_allrole           => 'manager',
      cmsd_allrole          => 'server',
      xrootd_seclib         => 'libXrdSec.so',
      xrootd_monitor        => $xrootd_monitor,
      ofs_authlib           => $ofs_authlib,
      ofs_authorize         => true,
      xrd_ofsosslib         => 'libXrdDPMOss.so.3',
      cmsd_ofsosslib        => 'libXrdPss.so',
      pss_setopt            => [
        'ConnectTimeout 30',
        'RequestTimeout 30',
        'RedirectLimit 0'],
      ofs_cmslib            => 'libXrdDPMFinder.so.3',
      ofs_forward           => 'all',
      xrd_network           => 'nodnr',
      xrd_timeout           => $xrd_timeout,
      xrd_report            => $xrd_report,
      xrd_debug             => $dpm_xrootd_debug,
      sec_protocol          => [$sec_protocol_redir, $sec_protocol_local],
      sec_level             => $xrootd_sec_level,
      dpm_listvoms          => $dpm_listvoms,
      dpm_mmreqhost         => $dpm_mmreqhost,
      dpm_xrootd_serverport => $dpm_xrootd_serverport,
      dpm_enablecmsclient   => true,
      oss_statlib           => $oss_statlib,
    }

    create_resources('dmlite::xrootd::create_redir_config', $dpm_xrootd_fedredirs, $federation_defaults)

    #added atlas digauth file
    $array_feds = keys($dpm_xrootd_fedredirs)
    if member($array_feds, 'atlas') {
      $digauth_filename = '/etc/xrootd/digauth_atlas.cf'
      xrootd::create_digauthfile{$digauth_filename:
        host  => 'atlint04.slac.stanford.edu',
        group => '/atlas',
      }
    }

    $dpm_cmsd_fedredirs = $dpm_xrootd_fedredirs.filter | $fed,$value | { $value['cmsd_port']!=undef }

    $xrootd_instances_options_fed = map_hash($dpm_xrootd_fedredirs, "-l /var/log/xrootd/xrootd.log -c /etc/xrootd/xrootd-dpmfedredir_%s.cfg ${log_style_param}")
    $cmsd_instances_options_fed = map_hash($dpm_cmsd_fedredirs, "-l /var/log/xrootd/cmsd.log -c /etc/xrootd/xrootd-dpmfedredir_%s.cfg ${log_style_param}")

  } else {
    $xrootd_instances_options_redir = {}
    $xrootd_instances_options_fed = {}
    $cmsd_instances_options_fed = {}
  }

  $xrootd_instances_options_all = [
    $xrootd_instances_options_redir,
    $xrootd_instances_options_disk,
    $xrootd_instances_options_fed
  ]

  $exports = {
    'DPM_HOST'             => $dpmhost,
    'DPNS_HOST'            => $nshost,
    'DPM_CONRETRY'         => 0,
    'DPNS_CONRETRY'        => 0,
    'XRD_MAXREDIRECTCOUNT' => 1,
  }

  if $xrootd_jemalloc and $facts['os']['family'] == 'RedHat' {
    $jemalloc = $facts['os']['release']['major'] ? {
      '6' => '/usr/lib64/libjemalloc.so.1',
      '7' => '/usr/lib64/libjemalloc.so.1',
      '8' => '/usr/lib64/libjemalloc.so.2',
      default => undef,
    }
    package {$jemalloc_package:
      ensure => present
    }
  } else {
    $jemalloc = undef
  }

  if $dpm_xrootd_debug {
    $daemon_corefile_limit = 'unlimited'
  } else {
    $daemon_corefile_limit = undef
  }


  if ($log_style_param == '-k fifo') {  # delete all non-fifo files
    exec{'delete .xrootd.log files':
      command => '/bin/find /var/log/xrootd -type f -name .xrootd.log -exec rm {} \;',
      path    => '/bin/:/usr/bin/',
      unless  => '[ "`/bin/find /var/log/xrootd -type f -name .xrootd.log -type f`" = "" ]'
    }
  } else {  # do not use fifos, so delete all fifo files
    exec{'delete .xrootd.log files':
      command => '/bin/find /var/log/xrootd -type f -name .xrootd.log -exec rm {} \;',
      path    => '/bin/:/usr/bin/',
      unless  => '[ "`/bin/find /var/log/xrootd -type f -name .xrootd.log -type p`" = "" ]'
    }
  }

  #use syconfig in SL6, systemd otherwise

  if versioncmp($facts['os']['release']['major'], '7') >= 0 {

    if member($nodetype, 'disk') {

      xrootd::create_systemd{'xrootd@dpmdisk':
        xrootd_user           => $lcgdm_user,
        xrootd_group          => $lcgdm_user,
        exports               => $exports,
        jemalloc              => $jemalloc,
        daemon_corefile_limit => $daemon_corefile_limit,
        after_conf            => $after_conf_disk,
        runtime_dir           => $runtime_dir
      }
    }

    if member($nodetype, 'head') {
      #get federation hashes
      $array_fed = keys($dpm_xrootd_fedredirs)

      if size($array_fed) > 0 {
        $array_fed_final = prefix($array_fed,'dpmfedredir_')
        $array_cmsd = $array_fed.filter | $fed | {$dpm_xrootd_fedredirs[$fed]['cmsd_port']!=undef}
        $xrootd_instances = flatten (concat (['dpmredir'],$array_fed_final))
        $cmsd_instances_final = prefix(prefix($array_cmsd,'dpmfedredir_'),'cmsd@')
      } else {
        $xrootd_instances = ['dpmredir']
        $cmsd_instances_final = undef
      }
      $xrootd_instances_final = prefix($xrootd_instances,'xrootd@')

      dmlite::xrootd::create_systemd_config{ $xrootd_instances_final:
        xrootd_user           => $lcgdm_user,
        xrootd_group          => $lcgdm_user,
        exports               => $exports,
        jemalloc              => $jemalloc,
        daemon_corefile_limit => $daemon_corefile_limit,
        after_conf            => $after_conf_head,
        runtime_dir           => $runtime_dir
      }
      if size($array_fed) > 0 {
        dmlite::xrootd::create_systemd_config{ $cmsd_instances_final:
          xrootd_user           => $lcgdm_user,
          xrootd_group          => $lcgdm_user,
          exports               => $exports,
          jemalloc              => $jemalloc,
          daemon_corefile_limit => $daemon_corefile_limit,
          after_conf            => $after_conf_head,
          runtime_dir           => $runtime_dir
        }
      }
    }

  } else {

    xrootd::create_sysconfig{$xrootd::config::sysconfigfile:
      xrootd_user              => $lcgdm_user,
      xrootd_group             => $lcgdm_user,
      xrootd_instances_options => $xrootd_instances_options_all,
      cmsd_instances_options   => $cmsd_instances_options_fed,
      exports                  => $exports,
      jemalloc                 => $jemalloc,
      daemon_corefile_limit    => $daemon_corefile_limit,
      enable_hdfs              => $enable_hdfs,
      java_home                => $java_home,
    }
  }

  # TODO: make the basedir point to $xrootd::config::configdir
  file{'/etc/xrootd/dpmxrd-sharedkey.dat':
    ensure  => file,
    owner   => $lcgdm_user,
    group   => $lcgdm_user,
    mode    => '0640',
    content => $dpm_xrootd_sharedkey
  }

  if versioncmp($facts['os']['release']['major'], '7') >= 0 {

    if member($nodetype, 'head') and member($nodetype, 'disk') {
      class{'xrootd::service':
        xrootd_instances =>  concat (['xrootd@dpmdisk'],$xrootd_instances_final),
        cmsd_instances   => $cmsd_instances_final,
        certificate      => "/etc/grid-security/${lcgdm_user}/dpmcert.pem",
        key              => "/etc/grid-security/${lcgdm_user}/dpmkey.pem",
      }

    } elsif member($nodetype, 'head') {
      class{'xrootd::service':
        xrootd_instances =>  $xrootd_instances_final,
        cmsd_instances   => $cmsd_instances_final,
        certificate      => "/etc/grid-security/${lcgdm_user}/dpmcert.pem",
        key              => "/etc/grid-security/${lcgdm_user}/dpmkey.pem",
      }

    } else {
      class{'xrootd::service':
        xrootd_instances =>  ['xrootd@dpmdisk'],
        certificate      => "/etc/grid-security/${lcgdm_user}/dpmcert.pem",
        key              => "/etc/grid-security/${lcgdm_user}/dpmkey.pem",
      }
    }

  } else {

    class{'xrootd::service':
      certificate => "/etc/grid-security/${lcgdm_user}/dpmcert.pem",
      key         => "/etc/grid-security/${lcgdm_user}/dpmkey.pem",
    }
  }

  file { '/var/log/xrootd/redir':
    ensure    => directory,
    owner     => $lcgdm_user,
    group     => $lcgdm_user,
    subscribe => [File['/var/log/xrootd']],
    require   => Class['xrootd::config'],
  }

  file { '/var/log/xrootd/disk':
    ensure    => directory,
    owner     => $lcgdm_user,
    group     => $lcgdm_user,
    subscribe => [File['/var/log/xrootd']],
    require   => Class['xrootd::config'],
  }

}
