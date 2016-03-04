# Configure and install an OpenIO oioeventagent service
define openiosds::oioeventagent (
  $action             = 'create',
  $type               = 'oio-event-agent',
  $num                = '0',

  $ns                 = undef,
  $ipaddress          = $::ipaddress,
  $bind_addr          = undef,
  $port               = $::openiosds::params::oioeventagent_port,
  $workers            = '2',
  $log_facility       = 'LOG_LOCAL0',
  $log_level          = 'info',
  $log_name           = undef,
  $log_address        = '/dev/log',
  $acct_update        = true,
  $queue_location     = undef,
  $retries_per_second = '30',
  $rdir_update        = true,

  $no_exec            = false,
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
  if ! has_interface_with('ipaddress',$ipaddress) { fail("${ipaddress} is invalid.") }
  if type3x($port) != 'integer' { fail("${port} is not an integer.") }
  if $bind_addr { $_bind_addr = $bind_addr }
  else { $_bind_addr = "tcp://${ipaddress}:${port}" }
  if type3x($workers) != 'integer' { fail("${workers} is not an integer.") }
  $valid_log_facilities = ['LOG_LOCAL0','LOG_LOCAL1','LOG_LOCAL2','LOG_LOCAL3','LOG_LOCAL4','LOG_LOCAL5','LOG_LOCAL6','LOG_LOCAL7']
  validate_re($log_facility,$valid_log_facilities,"${log_facility} is invalid.")
  $valid_log_levels = ['^critical$', '^error$', '^warn$', '^info$', '^debug$', '^trace$', '^blather$']
  validate_re($log_level, $valid_log_levels, "${log_level} is invalid.")
  if $log_name { $_log_name = $log_name }
  else { $_log_name = "${type}-${num}" }
  validate_string($_log_name)
  validate_bool($acct_update)
  if $queue_location { $_queue_location = $queue_location }
  else { $_queue_location = "${openiosds::sharedstatedir}/${ns}/${type}-${num}/oio-event-queue.db" }
  if type3x($retries_per_second) != 'integer' { fail("${retries_per_second} is not an integer.") }
  validate_bool($rdir_update)

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
    volume => dirname($_queue_location),
  } ->
  # Configuration
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf":
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}.conf.erb"),
    mode    => $openiosds::file_mode,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/oio-event-agent ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
