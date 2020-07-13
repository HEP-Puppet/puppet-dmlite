class dmlite::dav (
  String $package_name = $dmlite::dav::params::package_name,
  Stdlib::Unixpath $dmlite_conf = $dmlite::dav::params::dmlite_conf,
  Stdlib::Unixpath $dmlite_disk_conf = $dmlite::dav::params::dmlite_disk_conf,
  Enum['DPM','LFC','Plain'] $ns_type = $dmlite::dav::params::ns_type,
  String $ns_prefix = $dmlite::dav::params::ns_prefix,
  String $disk_prefix = $dmlite::dav::params::disk_prefix,
  String $ns_flags = $dmlite::dav::params::ns_flags,
  String $ns_anon = $dmlite::dav::params::ns_anon,
  Integer $ns_max_replicas = $dmlite::dav::params::ns_max_replicas,
  Enum['On','Off'] $ns_secure_redirect = $dmlite::dav::params::ns_secure_redirect,
  Optional[String] $ns_trusted_dns = $dmlite::dav::params::ns_trusted_dns,
  Optional[String] $ns_macaroon_secret = $dmlite::dav::params::ns_macaroon_secret,
  String $disk_flags = $dmlite::dav::params::disk_flags,
  String $disk_anon = $dmlite::dav::params::disk_anon,
  Stdlib::Unixpath $ssl_cert = $dmlite::dav::params::ssl_cert,
  Stdlib::Unixpath $ssl_key = $dmlite::dav::params::ssl_key,
  Stdlib::Unixpath $ssl_capath = $dmlite::dav::params::ssl_capath,
  String $ssl_options = $dmlite::dav::params::ssl_options,
  String $log_error = $dmlite::dav::params::log_error,
  String $log_transfer = $dmlite::dav::params::log_transfer,
  String $log_level = $dmlite::dav::params::log_level,
  String $user = $dmlite::dav::params::user,
  String $group = $dmlite::dav::params::group,
  Optional[Stdlib::Unixpath] $coredump_dir = $dmlite::dav::params::coredump_dir,
  Optional[String] $ulimit = $dmlite::dav::params::ulimit,
  Boolean $enable_ns = $dmlite::dav::params::enable_ns,
  Boolean $enable_disk = $dmlite::dav::params::enable_disk,
  Boolean $enable_https = $dmlite::dav::params::enable_https,
  Boolean $enable_http = $dmlite::dav::params::enable_http,
  Boolean $enable_keep_alive = $dmlite::dav::params::enable_keep_alive,
  Stdlib::Unixpath $mpm_model = $dmlite::dav::params::mpm_model,
  Boolean $enable_hdfs = $dmlite::dav::params::enable_hdfs,
  String $libdir = $dmlite::dav::params::libdir,

  Boolean $enable_ns_oidc = $dmlite::dav::params::enable_ns_oidc,
  String $ns_oidc_scope = $dmlite::dav::params::ns_oidc_scope,
  String $ns_oidc_metadataurl = $dmlite::dav::params::ns_oidc_metadataurl,
  String $ns_oidc_clientid = $dmlite::dav::params::ns_oidc_clientid,
  String $ns_oidc_clientsecret = $dmlite::dav::params::ns_oidc_clientsecret,
  String $ns_oidc_passphrase = $dmlite::dav::params::ns_oidc_passphrase,
  String $ns_oidc_redirecturi = $dmlite::dav::params::ns_oidc_redirecturi,
  String $ns_oidc_auth_verify_jwks_uri = $dmlite::dav::params::ns_oidc_auth_verify_jwks_uri,

  #dav ports
  Stdlib::Port $dav_http_port = 80,
  Stdlib::Port $dav_https_port = 443,
) inherits dmlite::dav::params {

  Class[dmlite::dav::install] -> Class[dmlite::dav::config] ~> Class[dmlite::dav::service]

  include('dmlite::dav::install')
  include('dmlite::dav::config')
  include('dmlite::dav::service')

}
