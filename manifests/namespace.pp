# Configure and install an OpenIO namespace
define openiosds::namespace (
  $action         = 'create',
  $ns             = undef,
  $conscience_url = undef,
  $zookeeper_url  = undef,
  $oioproxy_url   = undef,
  $eventagent_url = undef,
  $ecd_url        = undef,
  $meta1_digits   = undef,
  $udp_allowed    = undef,
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
  if $meta1_digits { validate_integer($meta1_digits,4,2) }
  if $udp_allowed { validate_string($udp_allowed) }

  if $openiosds::action == 'create' {
    # Path
    $required_path = [$openiosds::sysconfdir,"${openiosds::sysconfdir}/${ns}",$openiosds::logdir,"${openiosds::logdir}/${ns}",$openiosds::sharedstatedir,"${openiosds::sharedstatedir}/${ns}","${openiosds::sharedstatedir}/${ns}/coredump",$openiosds::runstatedir,$openiosds::spoolstatedir,"${openiosds::spoolstatedir}/${ns}"]
    file { $required_path:
      ensure => $openiosds::directory_ensure,
      owner  => $openiosds::user,
      group  => $openiosds::group,
      mode   => $openiosds::directory_mode,
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
