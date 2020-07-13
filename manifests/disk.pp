class dmlite::disk (
  String $token_password,
  Enum['ip','id'] $token_id = 'ip',
  Optional[String] $mysql_username = undef,
  Optional[String] $mysql_password = undef,
  Optional[Stdlib::Host] $mysql_host = undef,
  Integer $mysql_dir_space_report_depth = 6,
  Stdlib::Host $dpmhost = $::fqdn,
  Stdlib::Host $nshost = $::fqdn,
  Boolean $debuginfo = false,
  Integer $log_level = 1,
  Array[String] $logcomponents = [],
  Boolean $enable_space_reporting = false,
  Boolean $enable_dome = false,
  Boolean $enable_domeadapter = false,
  Optional[String] $headnode_domeurl = undef,
  Boolean $legacy = true,
  String $host_dn = '',
) {
  class {'dmlite::config::head':
    log_level     => $log_level,
    logcomponents => $logcomponents
  }
  class{'dmlite::install':
    debuginfo => $debuginfo
  }

  if $headnode_domeurl == undef {
    $_headnode_domeurl = "http://${dpmhost}:1094/domehead"
  }
  else {
    $_headnode_domeurl = $headnode_domeurl
  }

  if $enable_domeadapter and $enable_space_reporting{
    fail("'enable_domeadapter' and 'enable_space_reporting' options are mutual exclusive")
  }

  if $enable_dome  and $enable_domeadapter {
    class{'dmlite::plugins::domeadapter::config::disk':
      token_password => $token_password,
      token_id       => $token_id,
      dome_disk_url  => "http://${::fqdn}:1095/domedisk",
      dome_head_url  => $_headnode_domeurl,
      host_dn        => $host_dn
    }
    class{'dmlite::plugins::domeadapter::install':}

    class{'dmlite::plugins::adapter::install':
      uninstall      => true,
    }
    class{'dmlite::plugins::adapter::config::disk':
      token_password => $token_password,
      empty_conf     => true,
    }
  } else {
    class{'dmlite::plugins::adapter::config::disk':
      token_password => $token_password,
      token_id       => $token_id,
      dpmhost        => $dpmhost,
      nshost         => $nshost
    }
    class{'dmlite::plugins::adapter::install':}

    class{'dmlite::plugins::domeadapter::install':
      uninstall      => true,
    }
    class{'dmlite::plugins::domeadapter::config::disk':
      token_password => $token_password,
      empty_conf     => true,
      host_dn        => $host_dn
    }

  }

  if $enable_dome {
    #install the metapackage for disk
    if !$legacy {
      package{'dmlite-dpmdisk':
        ensure => absent,
      }
      package{'dmlite-dpmdisk-domeonly':
        ensure => present,
      }
    } else {
      package{'dmlite-dpmdisk-domeonly':
        ensure => absent,
      }
      package{'dmlite-dpmdisk':
        ensure => present,
      }
    }

    class{'dmlite::dome::config':
      dome_head                 => false,
      dome_disk                 => true,
      headnode_domeurl          => $_headnode_domeurl,
      restclient_cli_xrdhttpkey => $token_password
    }
    class{'dmlite::dome::install':}
  }

  if $enable_space_reporting {

    if $mysql_username == undef {
      fail("'mysql_username' not defined")
    }
    if $mysql_password == undef {
      fail("'mysql_password' not defined")
    }
    if $mysql_host == undef {
      fail("'mysql_host' not defined")
    }

    class{'dmlite::plugins::mysql::config':
      mysql_host                   => $mysql_host,
      mysql_username               => $mysql_username,
      mysql_password               => $mysql_password,
      dbpool_size                  => 10,
      enable_dpm                   => false,
      enable_ns                    => true,
      enable_io                    => true,
      mysql_dir_space_report_depth => $mysql_dir_space_report_depth,
    }
    class{'dmlite::plugins::mysql::install':}
  }
}
