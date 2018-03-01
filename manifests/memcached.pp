# Configure and install an OpenIO memcached service
define openiosds::memcached (
  $action                 = 'create',
  $type                   = 'memcached',
  $num                    = '0',

  $ns                     = undef,
  $ipaddress              = $::ipaddress,
  $port                   = $::openiosds::params::memcached_port,
  $user                   = $::openiosds::params::user,
  $memory                 = 64,
  $connections            = 1024,

  $location               = $hostname,
  $slots                  = undef,
  $no_exec                = false,
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
  validate_string($user)
  validate_integer($memory)
  validate_integer($connections)

  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Package
  ensure_packages([$::openiosds::params::memcached_package_name],merge($::openiosds::params::package_install_options,{before => [Gridinit::Program["${ns}-${type}-${num}"]]}))
  # Service
  openiosds::service {"${ns}-${type}-${num}":
    action => $action,
    type   => $type,
    num    => $num,
    ns     => $ns,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/memcached -U 0 -p ${port} -u ${user} -c ${connections} -l ${ipaddress}",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
