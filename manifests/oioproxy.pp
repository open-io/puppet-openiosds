# Configure and install an OpenIO oioproxy service
define openiosds::oioproxy (
  $action         = 'create',
  $type           = 'oioproxy',
  $num            = '0',

  $ns             = undef,
  $ipaddress      = $::ipaddress,
  $port           = $::openiosds::params::oioproxy_port,
  $debug          = false,
  $prefermaster   = undef,

  $no_exec        = false,
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
  if $prefermaster {
    validate_string($prefermaster)
    $_prefermaster = "-O PreferMaster=${prefermaster}"
  }


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
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/oio-proxy ${verbose} ${_prefermaster} -p ${openiosds::runstatedir}/${ns}-${type}-${num}.pid -s OIO,${ns},${type},${num} ${ipaddress}:${port} ${ns}",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
