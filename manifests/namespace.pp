# Configure and install an OpenIO namespace
define openiosds::namespace (
  $action                    = 'create',
  $ns                        = undef,
  $conscience_url            = undef,
  $zookeeper_url             = undef,
  $oioproxy_url              = undef,
  $eventagent_url            = undef,
  $ecd_url                   = undef,
  $meta1_digits              = 3,
  $ns_flat_bits              = undef,
  $udp_allowed               = 'yes',
  $server_queue_max_delay    = undef,
  $meta_queue_max_delay      = undef,
  $server_queue_warn_delay   = undef,
  $server_fd_max_passive     = undef,
  $oio_log_outgoing          = undef,
  $events_common_pending_max = undef,
  $ns_storage_policy         = 'THREECOPIES',
  $ns_chunk_size             = undef,
  $sqliterepo_election_delay_ping_final = undef,
  $sqliterepo_election_delay_expire_slave = undef,
  $sqliterepo_election_delay_expire_master = undef,
  $sqliterepo_election_delay_expire_none = undef,
  $sqliterepo_outgoing_timeout_cnx_use = undef,
  $sqliterepo_outgoing_timeout_req_use = undef,
  $sqliterepo_outgoing_timeout_cnx_getvers = undef,
  $sqliterepo_outgoing_timeout_req_getvers = undef,
  $sqliterepo_outgoing_timeout_cnx_replicate = undef,
  $sqliterepo_outgoing_timeout_req_replicate = undef,
  $sqliterepo_outgoing_timeout_cnx_resync = undef,
  $sqliterepo_outgoing_timeout_req_resync = undef,
  $sqliterepo_election_wait_delay = undef,
  $sqliterepo_election_wait_quantum = undef,
  $sqliterepo_election_nowait_after = undef,
  $proxy_outgoing_timeout_stat = undef,
  $proxy_outgoing_timeout_conscience = undef,
  $proxy_outgoing_timeout_common = undef,
  $meta0_outgoing_timeout_common_req = undef,
  $meta1_outgoing_timeout_common_req = undef,
  $gridd_timeout_connect_common = undef,
  $resolver_cache_srv_max_default = undef,
  $resolver_cache_csm0_max_default = undef,
  $sqliterepo_cache_ttl_cool = undef,
  $sqliterepo_cache_ttl_hot = undef,
  $client_errors_cache_enabled = undef,
  $client_errors_cache_period = undef,
  $client_errors_cache_max = undef,
  $client_down_cache_avoid = undef,
  $ns_worm = undef,
  $meta2_max_versions = undef,
  $meta2_batch_maxlen = undef,
  $ns_service_update_policy     = {
    'meta2' => 'KEEP|3|1|',
    'sqlx'  => 'KEEP|1|1|',
    'rdir'  => 'KEEP|1|1|user_is_a_service=rawx'},
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }


  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  if $ns { validate_string($ns) }
  if $conscience_url { validate_string($conscience_url) }
  if $zookeeper_url { validate_string($zookeeper_url) }
  if $oioproxy_url { validate_string($oioproxy_url) }
  if $eventagent_url { validate_string($eventagent_url) }
  if $ecd_url { validate_string($ecd_url) }
  if $meta1_digits { validate_integer($meta1_digits,4,0) }
  if $ns_flat_bits { validate_integer($ns_flat_bits) }
  if $udp_allowed { validate_string($udp_allowed) }
  if $server_queue_max_delay { validate_integer($server_queue_max_delay) }
  if $meta_queue_max_delay { validate_integer($meta_queue_max_delay) }
  if $server_queue_warn_delay { validate_integer($server_queue_warn_delay) }
  if $server_fd_max_passive { validate_integer($server_fd_max_passive) }
  if $oio_log_outgoing { validate_string($oio_log_outgoing) }
  if $events_common_pending_max { validate_integer($events_common_pending_max) }
  if $ns_storage_policy { validate_string($ns_storage_policy) }
  if $ns_chunk_size { validate_integer($ns_chunk_size) }
  if $ns_service_update_policy { validate_hash($ns_service_update_policy) }
  if $sqliterepo_election_delay_ping_final { validate_string($sqliterepo_election_delay_ping_final) }
  if $sqliterepo_election_delay_expire_slave { validate_string($sqliterepo_election_delay_expire_slave) }
  if $sqliterepo_election_delay_expire_master { validate_string($sqliterepo_election_delay_expire_master) }
  if $sqliterepo_election_delay_expire_none { validate_string($sqliterepo_election_delay_expire_none) }
  if $sqliterepo_outgoing_timeout_cnx_use { validate_string($sqliterepo_outgoing_timeout_cnx_use) }
  if $sqliterepo_outgoing_timeout_req_use { validate_string($sqliterepo_outgoing_timeout_req_use) }
  if $sqliterepo_outgoing_timeout_cnx_getvers { validate_string($sqliterepo_outgoing_timeout_cnx_getvers) }
  if $sqliterepo_outgoing_timeout_req_getvers { validate_string($sqliterepo_outgoing_timeout_req_getvers) }
  if $sqliterepo_outgoing_timeout_cnx_replicate { validate_string($sqliterepo_outgoing_timeout_cnx_replicate) }
  if $sqliterepo_outgoing_timeout_req_replicate { validate_string($sqliterepo_outgoing_timeout_req_replicate) }
  if $sqliterepo_outgoing_timeout_cnx_resync { validate_string($sqliterepo_outgoing_timeout_cnx_resync) }
  if $sqliterepo_outgoing_timeout_req_resync { validate_string($sqliterepo_outgoing_timeout_req_resync) }
  if $sqliterepo_election_wait_delay { validate_string($sqliterepo_election_wait_delay) }
  if $sqliterepo_election_wait_quantum { validate_string($sqliterepo_election_wait_quantum) }
  if $sqliterepo_election_nowait_after { validate_string($sqliterepo_election_nowait_after) }
  if $proxy_outgoing_timeout_stat { validate_string($proxy_outgoing_timeout_stat) }
  if $proxy_outgoing_timeout_conscience { validate_string($proxy_outgoing_timeout_conscience) }
  if $proxy_outgoing_timeout_common { validate_string($proxy_outgoing_timeout_common) }
  if $meta0_outgoing_timeout_common_req { validate_string($meta0_outgoing_timeout_common_req) }
  if $meta1_outgoing_timeout_common_req { validate_string($meta1_outgoing_timeout_common_req) }
  if $gridd_timeout_connect_common { validate_string($gridd_timeout_connect_common) }
  if $resolver_cache_srv_max_default { validate_string($resolver_cache_srv_max_default) }
  if $resolver_cache_csm0_max_default { validate_string($resolver_cache_csm0_max_default) }
  if $sqliterepo_cache_ttl_cool { validate_string($sqliterepo_cache_ttl_cool) }
  if $sqliterepo_cache_ttl_hot { validate_string($sqliterepo_cache_ttl_hot) }
  if $client_errors_cache_enabled { validate_string($client_errors_cache_enabled) }
  if $client_errors_cache_period { validate_string($client_errors_cache_period) }
  if $client_errors_cache_max { validate_string($client_errors_cache_max) }
  if $client_down_cache_avoid { validate_bool($client_down_cache_avoid) }
  if $ns_worm { validate_bool($ns_worm) }
  if $server_periodic_decache_max_bases { validate_string($server_periodic_decache_max_bases) }
  if $server_periodic_decache_period { validate_string($server_periodic_decache_period) }
  if $meta2_max_versions { validate_string($meta2_max_versions) }
  if $meta2_batch_maxlen { validate_integer($meta2_max_versions, 100000, 1) }

  if $openiosds::action == 'create' {
    # Path
    $required_path = [$openiosds::sysconfdir,"${openiosds::sysconfdir}/${ns}",$openiosds::sharedstatedir,"${openiosds::sharedstatedir}/${ns}","${openiosds::sharedstatedir}/${ns}/coredump",$openiosds::runstatedir,$openiosds::spoolstatedir,"${openiosds::spoolstatedir}/${ns}"]
    file { $required_path:
      ensure => $openiosds::directory_ensure,
      owner  => $openiosds::user,
      group  => $openiosds::group,
      mode   => $openiosds::directory_mode,
    }
    # Log path
    file { [$openiosds::logdir,"${openiosds::logdir}/${ns}"]:
      ensure => $openiosds::directory_ensure,
      owner  => $openiosds::user_log,
      group  => $openiosds::group_log,
      mode   => $openiosds::directory_mode_log,
    }

    if $conscience_url or $zookeeper_url or $oioproxy_url or $eventagent_url or $ecd_url {
      file { "${openiosds::sysconfdir_globald}/${ns}":
        ensure  => $openiosds::file_ensure,
        content => template('openiosds/sds-ns.conf.erb'),
        owner   => $openiosds::user,
        group   => $openiosds::group,
        mode    => $openiosds::file_mode,
        notify  => $notify,
      }
    }
  }

}
