# Configure and install an OpenIO service
define openiosds::service (
  $action  = 'create',
  $type    = undef,
  $num     = undef,
  $ns      = undef,
  $volume  = undef,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  validate_integer($num)
  if $ns { validate_string($ns) }
  if $volume { validate_string($volume) }

  # Path
  if $ns { $service_path = "${ns}/${type}-${num}" }
  else   { $service_path = "${type}-${num}" }
  if $volume and ! defined(File[$volume]) { $required_path = ["${openiosds::sysconfdir}/${service_path}","${openiosds::spoolstatedir}/${service_path}",$volume] }
  else { $required_path = ["${openiosds::sysconfdir}/${service_path}","${openiosds::spoolstatedir}/${service_path}"] }

  file { $required_path:
    ensure => $openiosds::directory_ensure,
    owner  => $openiosds::user,
    group  => $openiosds::group,
    mode   => $openiosds::directory_mode,
  }
  # Logs
  file { "${openiosds::logdir}/${service_path}":
    ensure => $openiosds::directory_ensure,
    owner  => $openiosds::user_log,
    group  => $openiosds::group_log,
    mode   => $openiosds::directory_mode_log,
  }

}
