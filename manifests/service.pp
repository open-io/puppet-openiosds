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
  if type3x($num) != 'integer' { fail("${num} is not an integer.") }
  if $ns { validate_string($ns) }
  if $volume { validate_string($volume) }

  # Path
  if $ns { $service_path = "${ns}/${type}-${num}" }
  else   { $service_path = "${type}-${num}" }
  if $volume { $required_path = ["${openiosds::sysconfdir}/${service_path}","${openiosds::spoolstatedir}/${service_path}",$volume,"${openiosds::logdir}/${service_path}"] }
  else { $required_path = ["${openiosds::sysconfdir}/${service_path}","${openiosds::spoolstatedir}/${service_path}","${openiosds::logdir}/${service_path}"] }

  file { $required_path:
    ensure => $openiosds::directory_ensure,
    owner  => $openiosds::user,
    group  => $openiosds::group,
    mode   => $openiosds::directory_mode,
  }

}
