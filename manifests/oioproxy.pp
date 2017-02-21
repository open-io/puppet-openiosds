# Configure and install an OpenIO oioproxy service
define openiosds::oioproxy (
  $action                = 'create',
  $type                  = 'oioproxy',
  $num                   = '0',

  $ns                    = undef,
  $ipaddress             = $::ipaddress,
  $port                  = $::openiosds::params::oioproxy_port,
  $debug                 = false,
  $cmdOptions            = undef,
  $preferMaster          = undef,
  $preferSlave           = undef,
  $preferMasterForWrites = undef,
  $forceMaster           = undef,

  $no_exec               = false,
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
  if $cmdOptions {
    validate_string($cmdOptions)
    $_cmdoptions = $cmdOptions
  }
  else {
    if $debug { $verbose = '-v ' }
    if $preferMaster {
      validate_string($preferMaster)
      $_preferMaster = "-O PreferMaster=${preferMaster}"
    }
    if $preferSlave {
      validate_string($preferSlave)
      $_preferSlave = "-O PreferSlave=${preferSlave}"
    }
    if $preferMasterForWrites {
      validate_string($preferMasterForWrites)
      $_preferMasterForWrites = "-O PreferMasterForWrites=${preferMasterForWrites}"
    }
    if $forceMaster {
      validate_string($forceMaster)
      $_forceMaster = "-O ForceMaster=${forceMaster}"
    }
    $_cmdoptions = join(([$verbose, $_preferMaster, $_preferSlave,
      $_preferMasterForWrites, $_forceMaster].reduce([]) |$memo, $x|
      { if $x == undef { $memo } else {$memo << $x} }),' ')
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
    command => "${openiosds::bindir}/oio-proxy -p ${openiosds::runstatedir}/${ns}-${type}-${num}.pid -s OIO,${ns},${type},${num} ${ipaddress}:${port} ${_cmdoptions} ${ns}",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
