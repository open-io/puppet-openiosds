define openiosds::oioeventagent (
  $action       = 'create',
  $type         = 'oio-event-agent',
  $num          = '0',

  $ns           = undef,
  $ipaddress    = "${ipaddress}",
  $bind_addr    = undef,
  $port         = '6008',
  $workers      = '2',
  $log_facility = 'LOG_LOCAL0',
  $log_level    = 'INFO',
  $log_name     = undef,
  $log_address  = '/dev/log',

  $conscience_url = undef,
  $zookeeper_url  = undef,
  $oioproxy_url   = undef,
  $eventagent_url = undef,

  $no_exec      = false,
) {

  include openiosds

  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  if type($num) != 'integer' { fail("${num} is not an integer.") }

  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("$ipaddress is invalid.") }
  if type($port) != 'integer' { fail("$port is not an integer.") }
  if $bind_addr { $_bind_addr = $bind_addr }
  else { $_bind_addr = "tcp://${ipaddress}:${port}" }
  if type($workers) != 'integer' { fail("$workers is not an integer.") }
  $log_facilities = ['LOG_LOCAL0','LOG_LOCAL1','LOG_LOCAL2','LOG_LOCAL3','LOG_LOCAL4','LOG_LOCAL5','LOG_LOCAL6','LOG_LOCAL7']
  validate_re($log_facility,$log_facilities,"$log_facility is invalid.")
  $valid_log_level = ['^critical$', '^error$', '^warn$', '^info$', '^debug$', '^trace$', '^blather$']
  validate_re($log_level, $log_levels, "${log_level} is invalid.")
  if $log_name { $_log_name = $log_name }
  else { $_log_name = "${type}-${num}" }
  validate_string($log_name)

  validate_bool($no_exec)


  # Namespace
  if $action == 'create' {
    openiosds::namespace {$ns:
      action         => $action,
      ns             => $ns,
      conscience_url => $conscience_url,
      zookeeper_url  => $zookeeper_url,
      oioproxy_url   => $oioproxy_url,
      eventagent_url => $eventagent_url,
      no_exec        => $no_exec,
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
  file { "${type}-${num}/${type}-${num}.conf":
    path    => "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf",
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}.conf.erb"),
    mode    => $openiosds::file_mode,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action => $action,
    command => "${openiosds::bindir}/oio-event-agent ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf",
    group => "${ns},${type},${type}-${num}",
    uid => $openiosds::user,
    gid => $openiosds::group,
    no_exec => $no_exec,
  }

}
