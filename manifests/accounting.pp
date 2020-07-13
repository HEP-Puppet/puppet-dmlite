# EGI StaR accounting - https://wiki.egi.eu/wiki/APEL/Storage
# For publishing data in the EGI it is necessary to create
# eu.egi.storage.accounting service for DPM headnode in GOCDB
# (https://goc.egi.eu) with "Host DN" set to certificate subject
# Usage:
#   class { '::dmlite::accounting':
#     site_name => 'praguelcg2',
#   }
class dmlite::accounting (
  Boolean $enabled = hiera('dmlite::accounting::enabled',true),
  String $cron_interval = hiera('dmlite::accounting::cron_interval','daily'),
  String $bdii_url = hiera('dmlite::accounting::bdii_url','ldap://lcg-bdii.cern.ch:2170'),
  String $broker_network = hiera('dmlite::accounting::broker_network','PROD'),
  Optional[Stdlib::Host] $broker_host = hiera('dmlite::accounting::broker_host',undef),
  Optional[Stdlib::Port] $broker_port = hiera('dmlite::accounting::broker_port',undef),
  Boolean $use_ssl = hiera('dmlite::accounting::use_ssl',true),
  Optional[Stdlib::Unixpath] $certificate = hiera('dmlite::accounting::certificate','/etc/grid-security/dpmmgr/dpmcert.pem'),
  Optional[Stdlib::Unixpath] $key = hiera('dmlite::accounting::key','/etc/grid-security/dpmmgr/dpmkey.pem'),
  Optional[Stdlib::Unixpath] $capath = hiera('dmlite::accounting::capath','/etc/grid-security/certificates'),

  Optional[String] $server_cert = hiera('dmlite::accounting::server_cert',undef),
  String $messaging_destination = hiera('dmlite::accounting::messaging_destination','/queue/global.accounting.storage.central'),
  Stdlib::Unixpath $messaging_path = hiera('dmlite::accounting::messaging_path','/var/spool/apel/outgoing'),

  String $site_name = hiera('dmlite::accounting::site_name',''),

  Stdlib::Unixpath $nsconfig = hiera('dmlite::accounting::nsconfig','/usr/etc/NSCONFIG'),

  Stdlib::Host $dbhost = hiera('dmlite::accounting::dbhost','localhost'),
  String $dbuser = hiera('dmlite::accounting::dbuser',''),
  String $dbpwd = hiera('dmlite::accounting::dbpwd',''),
  String $nsdbname = hiera('dmlite::accounting::nsdbname','cns_db'),
  String $dpmdbname = hiera('dmlite::accounting::dpmdbname','dpm_db'),

  Stdlib::Unixpath $log_file = hiera('dmlite::accounting::log_file','/var/log/apel/ssmsend.log'),
  String $log_level = hiera('dmlite::accounting::log_level', 'INFO'),
  Boolean $console = hiera('dmlite::accounting::console', true),
  String $ssm_url = hiera('dmlite::accounting::ssm_url', ''),

) {

  if $site_name == '' {
    fail("'site_name' not defined")
  }

  # install
  if $enabled {
    package {['python-daemon','python-ldap','python-lockfile','stomppy']:
      ensure => 'installed',
    }
  }
  # apel-ssm also available in UMD repository
  if $enabled and $ssm_url == '' {
    if $facts['os']['family'] == 'RedHat' {
      $ssm_package_url = $facts['os']['release']['major'] ? {
        '6' => 'https://github.com/apel/ssm/releases/download/2.3.0-2/apel-ssm-2.3.0-2.el6.noarch.rpm',
        '7' => 'https://github.com/apel/ssm/releases/download/2.3.0-2/apel-ssm-2.3.0-2.el7.noarch.rpm',
        default => fail("EGI StaR accounting enabled but ${facts['os']['name']}${facts['os']['release']['major']} is not supported")
      }
    }
  } else {
    $ssm_package_url = $ssm_url
  }
  if !$ssm_package_url {
    fail("missing ssm_url on unsupported os ${facts['os']['family']} (${facts['os']['name']} ${facts['os']['release']['major']})")
  }
  package { 'apel-ssm':
    ensure   => $enabled ? {
      true  => 'installed',
      false => absent,
    },
    source   => $ssm_package_url,
    provider => 'rpm'
  }

  file {'/etc/apel/sender.cfg':
    ensure  => $enabled ? {
      true  => present,
      false => absent,
    },
    owner   => 'root',
    group   => 'root',
    content => template('dmlite/ssm/sender.cfg.erb'),
    require => Package['apel-ssm']
  }

  # do not break in case the new parameters are not defined
  if $dbuser == '' {
    $cron_content = inline_template('#!/bin/sh
/bin/mkdir -p /var/spool/apel/outgoing/`date +%Y%m%d` && /usr/share/dmlite/StAR-accounting/star-accounting.py --reportgroups --nsconfig=<%= @nsconfig %> --site=<%= @site_name %> > /var/spool/apel/outgoing/`date +%Y%m%d`/`date +%Y%m%d%H%M%S` && ssmsend
')
  } else {
    $cron_content = inline_template('#!/bin/sh
/bin/mkdir -p /var/spool/apel/outgoing/`date +%Y%m%d` && /usr/share/dmlite/StAR-accounting/star-accounting.py --reportgroups --dbhost=<%= @dbhost %> --dbuser=<%= @dbuser %> --dbpwd=<%= @dbpwd %> --nsdbname=<%= @nsdbname %> --dpmdbname=<%= @dpmdbname %> --site=<%= @site_name %> > /var/spool/apel/outgoing/`date +%Y%m%d`/`date +%Y%m%d%H%M%S` && ssmsend
')
  }

  file {"/etc/cron.${cron_interval}/dmlite-StAR-accounting":
    ensure  => $enabled ? {
      true  => present,
      false => absent,
    },
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => $cron_content,
    require => Package['apel-ssm']
  }
  
  #purge old cron
  cron { 'dmlite-star-accounting':
    ensure => absent,
  }

}
