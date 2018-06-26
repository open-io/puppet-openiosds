# Configure and install an OpenIO oioeventagent service
define openiosds::oioeventagent (
  $action                = 'create',
  $type                  = 'oio-event-agent',
  $num                   = '0',

  $ns                    = undef,
  $ipaddress             = $::ipaddress,
  $port                  = $::openiosds::params::oioeventagent_port,
  $workers               = undef,
  $concurrency           = undef,
  $log_facility          = 'LOG_LOCAL0',
  $log_level             = 'info',
  $log_name              = undef,
  $log_address           = '/dev/log',
  $acct_update           = true,
  $queue_url             = undef,
  $rdir_update           = true,
  $tube                  = 'oio',
  $quarantine            = false,
  $quarantine_queue_url  = undef,
  $replication           = false,
  $replication_queue_url = undef,
  $rebuild               = true,
  $rebuild_queue_url     = undef,

  $no_exec               = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  validate_integer($num)
  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("${ipaddress} is invalid.") }
  validate_integer($port)
  if $workers { validate_integer($workers) }
  if $concurrency { validate_integer($concurrency) }
  $valid_log_facilities = ['LOG_LOCAL0','LOG_LOCAL1','LOG_LOCAL2','LOG_LOCAL3','LOG_LOCAL4','LOG_LOCAL5','LOG_LOCAL6','LOG_LOCAL7']
  validate_re($log_facility,$valid_log_facilities,"${log_facility} is invalid.")
  $valid_log_levels = ['^critical$', '^error$', '^warn$', '^info$', '^debug$', '^trace$', '^blather$']
  validate_re($log_level, $valid_log_levels, "${log_level} is invalid.")
  if $log_name { $_log_name = $log_name }
  else { $_log_name = "${type}-${num}" }
  validate_string($_log_name)
  validate_bool($acct_update)
  if $queue_url { $_queue_url = $queue_url }
  else { $_queue_url = "beanstalk://${ipaddress}:${::openiosds::params::beanstalkd_port}" }
  validate_bool($rdir_update)
  validate_string($tube)
  if $quarantine { validate_string($quarantine_queue_url) }
  if $replication { validate_string($replication_queue_url) }
  if $rebuild_queue_url { $_rebuild_queue_url = $rebuild_queue_url }
  else { $_rebuild_queue_url = "beanstalk://${ipaddress}:${::openiosds::params::beanstalkd_port}" }
  if $rebuild { validate_string($_rebuild_queue_url) }

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
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf":
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}.conf.erb"),
    mode    => $openiosds::file_mode,
  } ->
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/oio-event-handlers.conf":
    ensure  => $openiosds::file_ensure,
    content => template('openiosds/oio-event-handlers.conf.erb'),
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
