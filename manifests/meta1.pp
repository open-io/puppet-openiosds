define openiosds::meta1 (
  $action         = 'create',
  $type           = 'meta1',
  $num            = '0',

  $ns             = undef,
  $ipaddress      = "${ipaddress}",
  $port           = '6002',
  $debug          = false,

  $conscience_url = undef,
  $zookeeper_url  = undef,
  $oioproxy_url   = undef,
  $eventagent_url = undef,

  $no_exec        = false,
) {

  include openiosds

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
    openiosds::namespace {$ns:
      action         => $action,
      ns             => $ns,
      conscience_url => $conscience_url,
      zookeeper_url  => $zookeeper_url,
      oioproxy_url   => $oioproxy_url,
      eventagent_url => $eventagent_url,
      no_exec        => $no_exec,
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
    command => "${openiosds::bindir}/oio-meta1-server ${verbose} -p ${openiosds::runstatedir}/${ns}-${type}-${num}.pid -s OIO,${ns},${type},${num} -O Endpoint=${ipaddress}:${port} ${ns} ${openiosds::sharedstatedir}/${ns}/${type}-${num}",
    group => "${ns},${type},${type}-${num}",
    uid => $openiosds::user,
    gid => $openiosds::group,
    no_exec => $no_exec,
  }

}
