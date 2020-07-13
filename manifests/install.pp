class dmlite::install (
  Boolean $debuginfo = false
) inherits dmlite::params {

  package {'dmlite-libs':
    ensure => present;
  }

  if $debuginfo {
    package {'dmlite-debuginfo':
      ensure => present;
    }
  }

}
