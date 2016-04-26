# Configure and install an OpenIO beanstalkd service
define openiosds::beanstalkd (
  $action           = 'create',
  $type             = 'beanstalkd',
  $num              = '0',

  $ns               = undef,
  $ipaddress        = $::ipaddress,
  $port             = $::openiosds::params::beanstalkd_port,
  $binlogdir        = undef,
  $fsync            = '1000',
  $binlogsize       = '10240000',

  $location         = $hostname,
  $no_exec          = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Validation
  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("${ipaddress} is invalid.") }
  if type3x($port) != 'integer' { fail("${port} is not an integer.") }
  if $binlogdir { $_binlogdir = $binlogdir }
  else { $_binlogdir = "${openiosds::sharedstatedir}/${ns}/${type}-${num}" }
  validate_string($location)

  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Package
  ensure_packages([$::openiosds::params::beanstalkd_package_name],$::openiosds::params::package_install_options)
  # Service
  openiosds::service {"${ns}-${type}-${num}":
    action => $action,
    type   => $type,
    num    => $num,
    ns     => $ns,
    volume => $_binlogdir,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/beanstalkd -l ${ipaddress} -p ${port} -u ${::openiosds::user} -b ${_binlogdir} -f ${fsync} -s ${binlogsize}",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
