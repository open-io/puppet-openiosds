# Configure and install an OpenIO redis-sentinel service
define openiosds::redissentinel (
  $action           = 'create',
  $type             = 'redissentinel',
  $num              = '0',

  $ns               = undef,
  $ipaddress        = $::ipaddress,
  $port             = $::openiosds::params::redissentinel_port,
  $dir              = undef,
  $logfile          = undef,
  $pidfile          = undef,
  $auth_pass        = undef,
  $daemonize        = 'no',
  $down_after       = '1000',
  $failover_timeout = '180000',
  $master_name      = 'mymaster',
  $redis_host       = $::ipaddress,
  $redis_port       = $::openiosds::params::redis_port,
  $parallel_sync    = '1',
  $quorum           = '2',

  $no_exec          = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Validation
  validate_string($ns)
  if $auth_pass { validate_string($auth_pass) }
  if type3x($port) != 'integer' { fail("${port} is not an integer.") }
  if type3x($redis_port) != 'integer' { fail("${port} is not an integer.") }
  if type3x($quorum) != 'integer' { fail("${quorum} is not an integer.") }
  if type3x($parallel_sync) != 'integer' { fail("${parallel_sync} is not an integer.") }
  if $dir { $_dir = $dir }
  else { $_dir = "${openiosds::sharedstatedir}/${ns}/${type}-${num}" }
  if $logfile { $_logfile = $logfile }
  else { $_logfile = "${openiosds::logdir}/${ns}/${type}-${num}/${type}-${num}.log" }
  if $pidfile { $_pidfile = $pidfile }
  else { $_pidfile = "${openiosds::sharedstatedir}/${ns}/${type}-${num}/${type}-${num}.pid" }

  # Packages
  ensure_packages([$::openiosds::params::redis_package_name])
  # Service
  openiosds::service {"${ns}-${type}-${num}":
    action => $action,
    type   => $type,
    num    => $num,
    ns     => $ns,
    volume => $_dir,
  } ->
  # Configuration files
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/redis-sentinel.conf":
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
    command => "${openiosds::bindir}/redis-server ${openiosds::sysconfdir}/${ns}/${type}-${num}/redis-sentinel.conf --sentinel --daemonize ${daemonize}",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    limit   => {
      stack_size => '8192'
    },
    no_exec => $no_exec,
  }


}
