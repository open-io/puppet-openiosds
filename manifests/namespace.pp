define openiosds::namespace (
  $action         = 'create',
  $ns             = undef,
  $conscience_url = undef,
  $zookeeper_url  = undef,
  $oioproxy_url   = undef,
  $eventagent_url = undef,
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

  if $openiosds::action == 'create' {
    # Path
    $required_path = ["$openiosds::sysconfdir","$openiosds::sysconfdir/$ns","$openiosds::logdir","$openiosds::logdir/$ns","$openiosds::sharedstatedir","$openiosds::sharedstatedir/$ns","$openiosds::sharedstatedir/$ns/coredump","$openiosds::runstatedir","$openiosds::spoolstatedir","$openiosds::spoolstatedir/$ns"]
    file { $required_path:
      ensure => $openiosds::directory_ensure,
      owner  => $openiosds::user,
      group  => $openiosds::group,
      mode   => $openiosds::directory_mode,
    }

    if $conscience_url or $zookeeper_url or $oioproxy_url or $eventagent_url {
      if ! defined(Openiosds::Sdsagent['sds-agent-0']) {
        fail('You must include a sdsagent class to configure a namespace.')
      }
      file { "${openiosds::sysconfdir_globald}/${ns}":
        ensure  => $openiosds::file_ensure,
        content => template('openiosds/sds-ns.conf.erb'),
        owner   => $openiosds::user,
        group   => $openiosds::group,
        mode    => $openiosds::file_mode,
        notify  => Openiosds::Sdsagent['sds-agent-0'],
      }
    }
  }

}
