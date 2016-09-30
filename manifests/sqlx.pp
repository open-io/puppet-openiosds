# Configure and install an OpenIO sqlx service
define openiosds::sqlx (
  $action          = 'create',
  $type            = 'sqlx',
  $num             = '0',

  $ns              = undef,
  $ipaddress       = $::ipaddress,
  $port            = $::openiosds::params::sqlx_port,
  $debug           = false,
  $volume          = undef,
  $pidfile         = undef,
  $checks          = undef,
  $stats           = undef,
  $cmdline_options = '',
  $schema          = undef,

  $location        = $hostname,
  $slots           = undef,
  $no_exec         = false,
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
  validate_string($cmdline_options)
  validate_string($location)
  if $slots { validate_array($slots) }


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
  }
  if $schema == 'oiobox' {
    file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/sqlx":
      ensure  => $openiosds::file_ensure,
      content => template('openiosds/sqlx.mail.erb'),
      mode    => $openiosds::file_mode,
      before  => File["${openiosds::sysconfdir}/${ns}/watch/${type}-${num}.yml"],
    }
  }
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/oio-sqlx-server ${verbose} ${cmdline_options} -p ${_pidfile} -s OIO,${ns},${type},${num} -O Endpoint=${ipaddress}:${port} -O DirectorySchemas=${openiosds::sysconfdir}/${ns}/${type}-${num} ${ns} ${_volume}",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
    require => File["${openiosds::sysconfdir}/${ns}/watch/${type}-${num}.yml"],
  }

}
