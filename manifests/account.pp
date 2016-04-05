# Configure and install an OpenIO account service
define openiosds::account (
  $action                 = 'create',
  $type                   = 'account',
  $num                    = '0',

  $ns                     = undef,
  $ipaddress              = $::ipaddress,
  $port                   = $::openiosds::params::account_port,
  $redis_host             = $::ipaddress,
  $redis_port             = $::openiosds::params::redis_port,
  $checks                 = undef,
  $stats                  = undef,
  $sentinel_hosts         = undef,
  $sentinel_master_name   = undef,
  $workers                = undef,
  $backlog                = '2048',

  $no_exec                = false,
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
  validate_string($redis_host)
  if type3x($redis_port) != 'integer' { fail("${redis_port} is not an integer.") }
  if $checks { $_checks = $checks }
  else { $_checks = ['{type: tcp}'] }
  if $stats { $_stats = $stats }
  else { $_stats = ['{type: http, path: /status, parser: json}','{type: system}'] }
  if $sentinel_master_name {
    validate_string($sentinel_master_name)
    validate_string($sentinel_hosts)
    $_sentinel_master_name = $sentinel_master_name
  }
  if $workers { if type3x($workers) != 'integer' { fail("${workers} is not an integer.") } }
  if type3x($backlog) != 'integer' { fail("${backlog} is not an integer.") }

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
    command => "${openiosds::bindir}/oio-account-server ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
