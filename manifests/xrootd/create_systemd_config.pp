define dmlite::xrootd::create_systemd_config (
  $xrootd_user = undef,
  $xrootd_group = undef,
  $exports = undef,
  $jemalloc = undef,
  $daemon_corefile_limit  = undef,
  $after_conf = undef,
  $runtime_dir = undef,
) {
  xrootd::create_systemd{$name:
    xrootd_user           => $xrootd_user,
    xrootd_group          => $xrootd_group,
    exports               => $exports,
    jemalloc              => $jemalloc,
    daemon_corefile_limit => $daemon_corefile_limit,
    runtime_dir           => $runtime_dir,
    after_conf            => $after_conf
  }

}

