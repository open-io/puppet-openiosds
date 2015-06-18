define openiosds::sdsagentevent (
  $action = 'create',
  $type   = 'sds-agent-event',
  $num    = '0',

  $ns     = undef,
) {

  include openiosds

  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  if type($num) != 'integer' { fail("${num} is not an integer.") }

  validate_string($ns)


  # Namespace
  if $action == 'create' {
    openiosds::namespace {$ns:
      action         => $action,
      ns             => $ns,
      conscience_url => $conscience_url,
      zookeeper_url  => $zookeeper_url,
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
    command => "${openiosds::bindir}/oio-cluster-agent --child-evt=${ns} -s OIO,local,${type},${num} ${openiosds::sysconfdir}/${type}-${num}/${type}-${num}.conf",
    group => "${ns},${type},${type}-${num}",
    uid => $openiosds::user,
    gid => $openiosds::group,
  }

}
