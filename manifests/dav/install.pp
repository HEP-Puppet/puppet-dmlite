class dmlite::dav::install (
) inherits dmlite::dav::params {

    package {
      'lcgdm-dav-server':
        ensure => present;
    }

  $filecontent= template('dmlite/dav/fetch-crl-patch')

  exec { 'fetch-crl-patch':
    path    => '/usr/bin:/usr/sbin:/bin',
    command => "bash ${filecontent}",
    unless  => 'grep -q \'# chkconfig fetch-crl-cron on\' \'/etc/cron.d/fetch-crl\'',
    require => Class[fetchcrl],
  }
}
