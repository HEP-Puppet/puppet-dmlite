class dmlite::disk_hdfs (
  String $token_password,
  Enum['ip','id'] $token_id = 'ip',
  Integer $token_life = 1000,
  String $mysql_username,
  String $mysql_password,
  Stdlib::Host $mysql_host = 'localhost',
  Stdlib::Host $dpmhost = $::fqdn,
  Stdlib::Host $nshost = $::fqdn,
  Optional[String] $adminuser = undef,
  Boolean $debuginfo = false,
  Integer $log_level = 1,
  Array[String] $logcomponents = [],
  Optional[String] $hdfs_namenode = undef,
  Optional[Stdlib::Port] $hdfs_port = undef,
  Optional[String] $hdfs_user = undef,
  String $hdfs_mode = 'rw',
  Stdlib::Unixpath $hdfs_tmp_folder = '/tmp',
  Boolean $enable_io = true,
  Integer $hdfs_replication = 3,
  Boolean $enable_space_reporting = false,
) {
  class{'dmlite::config::head':
    log_level     => $log_level,
    logcomponents => $logcomponents
  }
  class{'dmlite::install':
    debuginfo => $debuginfo
  }

  Class[dmlite::plugins::hdfs::install] -> Class[dmlite::plugins::hdfs::config]

  class { 'dmlite::plugins::hdfs::config':
    token_password   => $token_password,
    token_id         => $token_id,
    token_life       => $token_life,
    hdfs_namenode    => $hdfs_namenode,
    hdfs_port        => $hdfs_port,
    hdfs_user        => $hdfs_user,
    hdfs_mode        => $hdfs_mode,
    hdfs_tmp_folder  => $hdfs_tmp_folder,
    enable_io        => $enable_io,
    hdfs_replication => $hdfs_replication,
  }
  class{'dmlite::plugins::hdfs::install':}

  class{'dmlite::plugins::mysql::config':
    mysql_host                   => $mysql_host,
    mysql_username               => $mysql_username,
    mysql_password               => $mysql_password,
    adminuser                    => $adminuser,
    enable_dpm                   => true,
    enable_ns                    => true,
    enable_io                    => $enable_space_reporting,
    mysql_dir_space_report_depth => 6,
  }

  class{'dmlite::plugins::mysql::install':}
}
