define openiosds::rawx (
  $action         = 'create',
  $type           = 'rawx',
  $num            = '0',

  $ns             = undef,
  $ipaddress      = $::ipaddress,
  $port           = '6004',

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

  # Packages
  if ! defined(Package[$openiosds::httpd_package_name]) {
    package { $openiosds::httpd_package_name:
      ensure          => installed,
      provider        => $openiosds::package_provider,
      allow_virtual   => false,
      install_options => $package_install_options,
      before          => File["${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-httpd.conf"],
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
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-httpd.conf":
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}-httpd.conf.erb"),
    mode    => $openiosds::file_mode,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/oio-svc-monitor -s OIO,${ns},${type},${num} -p 1 -m ${openiosds::bindir}/oio-rawx-monitor.py -i '${ns}|${type}|${ipaddress}:${port}' -c '${openiosds::httpd_daemon} -D FOREGROUND -f ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-httpd.conf'",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
