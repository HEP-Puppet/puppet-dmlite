class dmlite::base::install () inherits dmlite::base::params {
  Class[dmlite::base::config] -> Class[dmlite::base::install]

  if $dmlite::base::config::egiCA and !defined(Package['ca-policy-egi-core']) {
    ensure_packages(['ca-policy-egi-core'])
  }
}
