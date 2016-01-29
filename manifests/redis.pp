# Configure and install an OpenIO redis service
define openiosds::redis (
  $action         = 'create',
  $type           = 'redis',
  $num            = '0',

  $ns             = undef,
  $ipaddress      = $::ipaddress,
  $port           = '6010',
  $dir            = undef,
  $logfile        = undef,
  $pidfile        = undef,

  $no_exec        = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Validation
  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("${ipaddress} is invalid.") }
  if type3x($port) != 'integer' { fail("${port} is not an integer.") }
  if $dir { $_dir = $dir }
  else { $_dir = "${openiosds::sharedstatedir}/${ns}/${type}-${num}" }
  if $logfile { $_logfile = $logfile }
  else { $_logfile = "${openiosds::logdir}/${ns}/${type}-${num}/${type}-${num}.log" }
  if $pidfile { $_pidfile = $pidfile }
  else { $_pidfile = "${openiosds::sharedstatedir}/${ns}/${type}-${num}/${type}-${num}.pid" }

  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Package
  package { 'redis':
    ensure        => installed,
    allow_virtual => false,
  } ->
  # Service
  openiosds::service {"${ns}-${type}-${num}":
    action => $action,
    type   => $type,
    num    => $num,
    ns     => $ns,
    volume => $_dir,
  } ->
  # Configuration files
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf":
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}.conf.erb"),
    mode    => $openiosds::file_mode,
  } ->
  file { "${openiosds::logdir}/${ns}/${type}-${num}/${type}-${num}.log":
    ensure => $openiosds::file_ensure,
    owner  => $openiosds::user,
    group  => $openiosds::group,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    #command => "${openiosds::bindir}/oio-svc-monitor -s OIO,${ns},${type},${num} -p 1 -m ${openiosds::bindir}/oio-redis-monitor.py -i '${ns}|${type}|${ipaddress}:${port}' -c '/usr/bin/redis-server ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf --daemonize no'",
    command => "${openiosds::bindir}/redis-server ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf --daemonize no",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
