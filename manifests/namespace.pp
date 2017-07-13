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
  $ns_chunk_size = undef,
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
