define openiosds::rawx (
  $action         = 'create',
  $type           = 'rawx',
  $num            = '0',

  $ns             = undef,
  $ipaddress      = "${ipaddress}",
  $port           = '6004',

  $conscience_url = undef,
  $zookeeper_url  = undef,
  $oioproxy_url   = undef,
  $eventagent_url = undef,

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
      eventagent_url => $eventagent_url,
      no_exec        => $no_exec,
    }
  }


  # Packages
  package { 'openio-sds-mod-httpd':
    ensure => installed,
    provider => $openiosds::package_provider,
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
  file { "${type}-httpd.conf":
    path    => "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-httpd.conf",
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}-httpd.conf.erb"),
    mode    => $openiosds::file_mode,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/oio-svc-monitor -s OIO,${ns},${type},${num} -p 1 -m ${openiosds::bindir}/oio-rawx-monitor.py -i '${ns}|${type}|${ipaddress}:${port}' -c '${openiosds::httpd_daemon} -D FOREGROUND -f ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-httpd.conf'",
    group   => "${ns},${type},${type}-${num}",
    uid => $openiosds::user,
    gid => $openiosds::group,
    no_exec => $no_exec,
  }

}
