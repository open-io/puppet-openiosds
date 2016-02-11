# Configure and install an OpenIO conscienceagent service
define openiosds::conscienceagent (
  $action         = 'create',
  $type           = 'conscienceagent',
  $num            = '0',

  $ns             = undef,
  $log_facility   = 'LOG_LOCAL0',
  $log_level      = 'info',
  $log_address    = '/dev/log',
  $include_dir    = undef,
  $check_interval = '1',
  $rise           = '1',
  $fall           = '1',

  $no_exec         = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  if type3x($num) != 'integer' { fail("${num} is not an integer.") }
  validate_string($ns)
  $valid_log_facilities = ['LOG_LOCAL0','LOG_LOCAL1','LOG_LOCAL2','LOG_LOCAL3','LOG_LOCAL4','LOG_LOCAL5','LOG_LOCAL6','LOG_LOCAL7']
  validate_re($log_facility,$valid_log_facilities,"${log_facility} is invalid.")
  $valid_log_levels = ['^critical$', '^error$', '^warn$', '^info$', '^debug$', '^trace$', '^blather$']
  validate_re($log_level, $valid_log_levels, "${log_level} is invalid.")
  if $include_dir { $_include_dir = $include_dir }
  else { $_include_dir = "${openiosds::sysconfdir}/${ns}/watch" }
  if type3x($check_interval) != 'integer' { fail("${check_interval} is not an integer.") }
  if type3x($rise) != 'integer' { fail("${rise} is not an integer.") }
  if type3x($fall) != 'integer' { fail("${fall} is not an integer.") }

  validate_bool($no_exec)


  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Service
  openiosds::service {"${ns}-${type}-${num}":
    action => $action,
    type   => $type,
    num    => $num,
    ns     => $ns,
  } ->
  # Configuration
  file { $_include_dir:
    ensure  => $openiosds::directory_ensure,
    mode    => $openiosds::directory_mode,
    owner   => $openiosds::user,
    group   => $openiosds::group,
  } ->
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.yml":
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}.yml.erb"),
    mode    => $openiosds::file_mode,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/oio-conscience-agent ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.yml",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
