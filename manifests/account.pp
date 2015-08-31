define openiosds::account (
  $action         = 'create',
  $type           = 'account',
  $num            = '0',

  $ns                     = undef,
  $ipaddress              = $::ipaddress,
  $port                   = '6009',
  $redis_default_install  = false,
  $redis_host             = $::ipaddress,
  $redis_port             = '6010',

  $no_exec        = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Redis
  if $redis_default_install {
    package { 'redis':
      ensure => installed,
    } ->
    service { 'redis':
      ensure => running,
      enable => true,
      before => Openiosds::Service["${ns}-${type}-${num}"],
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
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/oio-svc-monitor -s OIO,${ns},${type},${num} -p 1 -m ${openiosds::bindir}/oio-account-monitor.py -i '${ns}|${type}|${ipaddress}:${port}' -c '${openiosds::bindir}/oio-account-server ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf'",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
