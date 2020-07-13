class dmlite::srm (
  Enum['mysql','oracle'] $dbflavor = $dmlite::srm::params::dbflavor,
  String $user = $dmlite::srm::params::user,
  String $group = $dmlite::srm::params::group,
  Stdlib::Host $dpmhost = $dmlite::srm::params::dpmhost,
  Stdlib::Host $nshost = $dmlite::srm::params::nshost,
) inherits dmlite::srm::params {

  Class[dmlite::srm::install] -> Class[dmlite::srm::config] -> Class[dmlite::srm::service]

  class{'dmlite::srm::install':
    user  => $user,
    group => $group
  }
  class{'dmlite::srm::config':
    dbflavor => $dbflavor,
    dpmhost  => $dpmhost,
    nshost   => $nshost
  }
  class{'dmlite::srm::service':}

}
