class dmlite::plugins::memcache(
  Array[String] $servers = $dmlite::plugins::memcache::params::servers,
  Boolean $enable_memcache = $dmlite::plugins::memcache::params::enable_memcache,
  Boolean $enable_memcache_cat = $dmlite::plugins::memcache::params::enable_memcache_cat,
  Boolean $enable_memcache_pool = $dmlite::plugins::memcache::params::enable_memcache_pool,
  Integer $pool_size = $dmlite::plugins::memcache::params::pool_size,
  String $user = $dmlite::params::user,
  String $group = $dmlite::params::group,
  Enum['ascii','binary'] $protocol = $dmlite::plugins::memcache::params::protocol,
  Enum['on','off'] $posix = $dmlite::plugins::memcache::params::posix,
  Integer $expiration_limit = $dmlite::plugins::memcache::params::expiration_limit,
  Enum['on','off'] $func_counter = $dmlite::plugins::memcache::params::func_counter,
  Integer $local_cache_size = $dmlite::plugins::memcache::params::local_cache_size,
) inherits dmlite::plugins::memcache::params {

  class{'dmlite::plugins::memcache::config':
    servers              => $servers,
    enable_memcache      => $enable_memcache,
    enable_memcache_cat  => $enable_memcache_cat,
    enable_memcache_pool => $enable_memcache_pool,
    pool_size            => $pool_size,
    user                 => $user,
    group                => $group,
    protocol             => $protocol,
    posix                => $posix,
    expiration_limit     => $expiration_limit,
    func_counter         => $func_counter,
    local_cache_size     => $local_cache_size,
  }
  if $enable_memcache {
    Class[dmlite::plugins::memcache::install] -> Class[dmlite::plugins::memcache::config]

    class{'dmlite::plugins::memcache::install':}
  }
}
