# Configure and install an OpenIO account service
define openiosds::account (
  $action                 = 'create',
  $type                   = 'account',
  $num                    = '0',

  $ns                     = undef,
  $ipaddress              = $::ipaddress,
  $port                   = '6009',
  $redis_default_install  = false,
  $redis_host             = $::ipaddress,
  $redis_port             = '6010',
  $checks                 = undef,
  $stats                  = undef,

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
  validate_bool($redis_default_install)
  validate_string($redis_host)
  if type3x($redis_port) != 'integer' { fail("${redis_port} is not an integer.") }
  if $checks { $_checks = $checks }
  else { $_checks = ['{type: tcp}'] }
  if $stats { $_stats = $stats }
  else { $_stats = ['{type: http, path: /status, parser: json}','{type: system}'] }

  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Redis
  if $redis_default_install {
    ensure_packages([$::openiosds::params::redis_package_name])
    unless $no_exec {
      service { $::openiosds::params::redis_service_name:
        ensure  => running,
        enable  => true,
        before  => Openiosds::Service["${ns}-${type}-${num}"],
        require => Package[$::openiosds::params::redis_package_name],
      }
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
