# Configure and install an OpenIO rdir service
define openiosds::rdir (
  $action         = 'create',
  $type           = 'rdir',
  $num            = '0',

  $ns             = undef,
  $ipaddress      = $::ipaddress,
  $port           = $::openiosds::params::rdir_port,
  $workers        = 1,
  $db_path        = undef,
  $checks         = undef,
  $stats          = undef,
  $worker_class   = 'sync',
  $threads        = 1,

  $location       = $hostname,
  $slots          = undef,
  $no_exec        = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Validation
  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("${ipaddress} is invalid.") }
  validate_integer($port)
  validate_integer($workers)
  if $db_path { $_db_path = $db_path }
  else { $_db_path = "${openiosds::sharedstatedir}/${ns}/${type}-${num}" }
  if $checks { $_checks = $checks }
  else { $_checks = ['{type: tcp}'] }
  if $stats { $_stats = $stats }
  else { $_stats = ["{type: volume, path: ${_db_path}}",'{type: http, path: /status, parser: json}','{type: system}'] }
  validate_string($location)
  if $slots { validate_array($slots) }
  validate_string($worker_class)
  validate_integer($threads)

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
    volume => $_db_path,
  } ->
  # Configuration files
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf":
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}.conf.erb"),
    mode    => $openiosds::file_mode,
  } ->
  file { "${openiosds::sysconfdir}/${ns}/watch/${type}-${num}.yml":
    ensure  => $openiosds::file_ensure,
    content => template('openiosds/service-watch.yml.erb'),
    mode    => $openiosds::file_mode,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/oio-rdir-server ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
