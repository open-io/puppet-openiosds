# Configure and install an OpenIO meta2 service
define openiosds::meta2 (
  $action         = 'create',
  $type           = 'meta2',
  $num            = '0',

  $ns             = undef,
  $ipaddress      = $::ipaddress,
  $port           = $::openiosds::params::meta2_port,
  $debug          = false,
  $volume         = undef,
  $pidfile        = undef,
  $checks         = undef,
  $stats          = undef,

  $no_exec        = false,
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
  validate_bool($debug)
  if $debug { $verbose = '-v ' }
  if $volume { $_volume = $volume }
  else { $_volume = "${openiosds::sharedstatedir}/${ns}/${type}-${num}" }
  if $pidfile { $_pidfile = $pidfile }
  else { $_pidfile = "${openiosds::runstatedir}/${ns}-${type}-${num}.pid" }
  if $checks { $_checks = $checks }
  else { $_checks = ['{type: tcp}'] }
  if $stats { $_stats = $stats }
  else { $_stats = ["{type: volume, path: ${_volume}}",'{type: meta}','{type: system}'] }


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
    volume => $_volume,
  } ->
  file { "${openiosds::sysconfdir}/${ns}/watch/${type}-${num}.yml":
    ensure  => $openiosds::file_ensure,
    content => template('openiosds/service-watch.yml.erb'),
    mode    => $openiosds::file_mode,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/oio-meta2-server ${verbose} -p ${_pidfile} -s OIO,${ns},${type},${num} -O Endpoint=${ipaddress}:${port} ${ns} ${_volume}",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
