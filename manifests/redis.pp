# Configure and install an OpenIO redis service
define openiosds::redis (
  $action                      = 'create',
  $type                        = 'redis',
  $num                         = '0',

  $ns                          = undef,
  $ipaddress                   = $::ipaddress,
  $port                        = $::openiosds::params::redis_port,
  $dir                         = undef,
  $logfile                     = undef,
  $pidfile                     = undef,
  $slaveof                     = undef,
  $daemonize                   = 'no',
  $tcp_backlog                 = '511',
  $timeout                     = '0',
  $tcp_keepalive               = '0',
  $rloglevel                   = 'notice',
  $databases                   = '16',
  $stop_writes_on_bgsave_error = 'yes',
  $rdbcompression              = 'yes',
  $rdbchecksum                 = 'yes',
  $dbfilename                  = 'dump.rdb',
  $slave_serve_stale_data      = 'yes',
  $slave_read_only             = 'yes',
  $slave_priority              = '100',
  $latency_monitor_threshold   = '0',
  $save                        = ['900 1','300 10','60 10000'],
  $maxclients                  = '10000',
  $maxmemory                   = '0',

  $location                    = $hostname,
  $slots                       = undef,
  $no_exec                     = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Validation
  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("${ipaddress} is invalid.") }
  validate_integer($port)
  if $dir { $_dir = $dir }
  else { $_dir = "${openiosds::sharedstatedir}/${ns}/${type}-${num}" }
  if $logfile { $_logfile = $logfile }
  else { $_logfile = "${openiosds::logdir}/${ns}/${type}-${num}/${type}-${num}.log" }
  if $pidfile { $_pidfile = $pidfile }
  else { $_pidfile = "${openiosds::sharedstatedir}/${ns}/${type}-${num}/${type}-${num}.pid" }
  if $slaveof { validate_string($slaveof) }
  validate_string($location)
  if $slots { validate_array($slots) }

  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Package
  ensure_packages([$::openiosds::params::redis_package_name],$::openiosds::params::package_install_options)
  # Service
  openiosds::service {"${ns}-${type}-${num}":
    action => $action,
    type   => $type,
    num    => $num,
    ns     => $ns,
    volume => $_dir,
  } ->
  # Configuration files
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/redis.conf":
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}.conf.erb"),
    mode    => $openiosds::file_mode,
    owner   => $openiosds::user,
    group   => $openiosds::group,
    require => Package[$::openiosds::params::redis_package_name],
  } ->
  file { "${openiosds::logdir}/${ns}/${type}-${num}/${type}-${num}.log":
    ensure => $openiosds::file_ensure,
    owner  => $openiosds::user,
    group  => $openiosds::group,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/redis-server ${openiosds::sysconfdir}/${ns}/${type}-${num}/redis.conf --daemonize ${daemonize}",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    limit   => {
      stack_size => '8192'
    },
    no_exec => $no_exec,
  }

}
