define openiosds::redis (
  $action         = 'create',
  $type           = 'redis',
  $num            = '0',

  $ns             = undef,
  $ipaddress      = "${ipaddress}",
  $port           = '6010',

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


  # Package
  package { "redis":
    ensure => installed,
    allow_virtual => false,
  } ->
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
  file { "${openiosds::logdir}/${ns}/${type}-${num}/${type}-${num}.log":
    ensure  => $openiosds::file_ensure,
    owner => $openiosds::user,
    group => $openiosds::group,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    #command => "${openiosds::bindir}/oio-svc-monitor -s OIO,${ns},${type},${num} -p 1 -m ${openiosds::bindir}/oio-redis-monitor.py -i '${ns}|${type}|${ipaddress}:${port}' -c '/usr/bin/redis-server ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf --daemonize no'",
    command => "${openiosds::bindir}/redis-server ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf --daemonize no",
    group   => "${ns},${type},${type}-${num}",
    uid => $openiosds::user,
    gid => $openiosds::group,
    no_exec => $no_exec,
  }

}
