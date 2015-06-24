define openiosds::account (
  $action         = 'create',
  $type           = 'account',
  $num            = '0',

  $ns             = undef,
  $ipaddress      = "${ipaddress}",
  $port           = '6009',
  $redis_host     = "${ipaddress}",
  $redis_port     = '6010',

  $conscience_url = undef,
  $zookeeper_url  = undef,
  $oioproxy_url   = undef,

  $no_exec        = false,
) {

  include openiosds

  # Namespace
  if $action == 'create' {
    openiosds::namespace {$ns:
      action         => $action,
      ns             => $ns,
      conscience_url => $conscience_url,
      zookeeper_url  => $zookeeper_url,
      oioproxy_url   => $oioproxy_url,
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
  # Configuration files
  file { "${type}-${num}/${type}-${num}.conf":
    path    => "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf",
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}.conf.erb"),
    mode    => $openiosds::file_mode,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/oio-svc-monitor -s OIO,${ns},${type},${num} -p 1 -m ${openiosds::bindir}/oio-account-monitor.py -i '${ns}|${type}|${ipaddress}:${port}' -c '${openiosds::bindir}/oio-account-server ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf'",
    group   => "${ns},${type},${type}-${num}",
    uid => $openiosds::user,
    gid => $openiosds::group,
    no_exec => $no_exec,
  }

}
