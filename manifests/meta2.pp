define openiosds::meta2 (
  $action         = 'create',
  $type           = 'meta2',
  $num            = '0',

  $ns             = undef,
  $ipaddress      = "${ipaddress}",
  $port           = '6003',
  $debug          = false,

  $no_exec        = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  if type($num) != 'integer' { fail("${num} is not an integer.") }

  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("$ipaddress is invalid.") }
  if type($port) != 'integer' { fail("$port is not an integer.") }
  validate_bool($debug)
  if $debug { $verbose = '-v ' }


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
    action => $action,
    command => "${openiosds::bindir}/oio-meta2-server ${verbose} -p ${openiosds::runstatedir}/${ns}-${type}-${num}.pid -s OIO,${ns},${type},${num} -O Endpoint=${ipaddress}:${port} ${ns} ${openiosds::sharedstatedir}/${ns}/${type}-${num}",
    group => "${ns},${type},${type}-${num}",
    uid => $openiosds::user,
    gid => $openiosds::group,
    no_exec => $no_exec,
  }

}
