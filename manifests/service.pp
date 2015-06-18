define openiosds::service (
  $action  = 'create',
  $type    = undef,
  $num     = undef,
  $ns      = undef,
) {

  include openiosds

  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  if type($num) != 'integer' { fail("${num} is not an integer.") }
  if $ns { validate_string($ns) }

  # Path
  if $ns { $service_path = "${ns}/${type}-${num}" }
  else   { $service_path = "${type}-${num}" }
  $required_path = ["${openiosds::sysconfdir}/${service_path}","${openiosds::spoolstatedir}/${service_path}","${openiosds::sharedstatedir}/${service_path}","${openiosds::logdir}/${service_path}"]

  file { $required_path:
    ensure => $openiosds::directory_ensure,
    owner  => $openiosds::user,
    group  => $openiosds::group,
    mode   => $openiosds::directory_mode,
  }

}
