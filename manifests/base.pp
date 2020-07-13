class dmlite::base (
  Integer $uid = $dmlite::base::params::uid,
  Integer $gid = $dmlite::base::params::gid,
  String $cert = $dmlite::base::params::cert,
  String $certkey = $dmlite::base::params::certkey,
  String $user = $dmlite::base::params::user,
) inherits dmlite::base::params {

  class { 'dmlite::base::config':
    uid     => $uid,
    gid     => $gid,
    cert    => $cert,
    certkey => $certkey,
    user    => $user,
  }

  class { 'dmlite::base::install':
  }
}
