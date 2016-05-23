# Configure and install an OpenIO rainx service
define openiosds::rainx (
  $action                     = 'create',
  $type                       = 'rainx',
  $num                        = '0',

  $ns                         = undef,
  $ipaddress                  = $::ipaddress,
  $port                       = $::openiosds::params::rainx_port,
  $default_oioblobindexer     = false,
  $documentRoot               = undef,
  $serverRoot                 = undef,
  $grid_hash_width            = '3',
  $grid_hash_depth            = '1',
  $checks                     = undef,
  $stats                      = undef,
  $serverName                 = 'localhost',
  $serverSignature            = 'Off',
  $serverTokens               = 'Prod',
  $typesConfig                = '/etc/mime.types',
  $prefork_MaxClients         = '150',
  $prefork_StartServers       = '5',
  $prefork_MinSpareServers    = '5',
  $prefork_MaxSpareServers    = '10',
  $worker_StartServers        = '5',
  $worker_MaxClients          = '100',
  $worker_MinSpareThreads     = '5',
  $worker_MaxSpareThreads     = '25',
  $worker_ThreadsPerChild     = '10',
  $worker_MaxRequestsPerChild = '0',

  $location                   = $hostname,
  $no_exec                    = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Validation
  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("${ipaddress} is invalid.") }
  validate_integer($port)
  validate_bool($default_oioblobindexer)
  if $documentRoot { $_documentRoot = $documentRoot }
  else { $_documentRoot = "${openiosds::sharedstatedir}/${ns}/${type}-${num}" }
  if $serverRoot { $_serverRoot = $serverRoot }
  else { $_serverRoot = "${openiosds::sharedstatedir}/${ns}/coredump" }
  validate_integer($grid_hash_width)
  validate_integer($grid_hash_depth)
  if $checks { $_checks = $checks }
  else { $_checks = ['{type: http, uri: /info}'] }
  if $stats { $_stats = $stats }
  else { $_stats = ['{type: rawx, path: /stat}','{type: system}'] }
  validate_string($serverName)
  validate_string($serverSignature)
  validate_string($serverTokens)
  validate_string($typesConfig)
  validate_integer($prefork_MaxClients)
  validate_integer($prefork_StartServers)
  validate_integer($prefork_MinSpareServers)
  validate_integer($prefork_MaxSpareServers)
  validate_integer($worker_StartServers)
  validate_integer($worker_MaxClients)
  validate_integer($worker_MinSpareThreads)
  validate_integer($worker_MaxSpareThreads)
  validate_integer($worker_ThreadsPerChild)
  validate_integer($worker_MaxRequestsPerChild)
  validate_string($location)

  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Packages
  ensure_packages([$::openiosds::httpd_package_name],$::openiosds::params::package_install_options)
  # Service
  openiosds::service {"${ns}-${type}-${num}":
    action => $action,
    type   => $type,
    num    => $num,
    ns     => $ns,
    volume => $_documentRoot,
  } ->
  # Configuration files
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-httpd.conf":
    ensure  => $openiosds::file_ensure,
    content => template('openiosds/dav-httpd.conf.erb'),
    mode    => $openiosds::file_mode,
    require => Package[$::openiosds::httpd_package_name],
  } ->
  file { "${openiosds::sysconfdir}/${ns}/watch/${type}-${num}.yml":
    ensure  => $openiosds::file_ensure,
    content => template('openiosds/service-watch.yml.erb'),
    mode    => $openiosds::file_mode,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::httpd_daemon} -D FOREGROUND -f ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-httpd.conf",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }
  if $documentRoot {
    file { $documentRoot:
      ensure => $openiosds::directory_ensure,
      owner  => $openiosds::user,
      group  => $openiosds::group,
      mode   => $openiosds::file_mode,
      before => File["${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-httpd.conf"],
    }
  }

}
