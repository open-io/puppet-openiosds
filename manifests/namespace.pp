define openiosds::namespace (
  $action         = 'create',
  $ns             = undef,
  $conscience_url = undef,
  $zookeeper_url  = undef,
  $oioproxy_url   = undef,
  $eventagent_url = undef,
  $no_exec        = false,
) {

  include openiosds

  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  if $ns { validate_string($ns) }
  if $conscience_url { validate_string($conscience_url) }
  if $zookeeper_url { validate_string($zookeeper_url) }
  if $oioproxy_url { validate_string($oioproxy_url) }
  if $eventagent_url { validate_string($eventagent_url) }
  validate_bool($no_exec)

  if $openiosds::action == 'create' {
  # Path
  $required_path = ["$openiosds::sysconfdir","$openiosds::sysconfdir/$ns","$openiosds::logdir","$openiosds::logdir/$ns","$openiosds::sharedstatedir","$openiosds::sharedstatedir/$ns","$openiosds::sharedstatedir/$ns/coredump","$openiosds::runstatedir","$openiosds::spoolstatedir","$openiosds::spoolstatedir/$ns"]

    file { $required_path:
      ensure => $openiosds::directory_ensure,
      owner => $openiosds::user,
      group => $openiosds::group,
      mode => $openiosds::directory_mode,
    }

    if $ns and $conscience_url {

      openiosds::sdsagent{$ns:
        no_exec => $no_exec,
      }

      file { "${openiosds::sysconfdir_globald}/${ns}":
        ensure => $openiosds::file_ensure,
        content => template("openiosds/sds-ns.conf.erb"),
        owner => $openiosds::user,
        group => $openiosds::group,
        mode => $openiosds::file_mode,
        notify => Openiosds::Sdsagent[$ns],
      }
    }
  }

}
