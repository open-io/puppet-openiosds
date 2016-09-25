# Configure and install an OpenIO ecd service
define openiosds::ecd (
  $action                      = 'create',
  $type                        = 'ecd',
  $num                         = '0',

  $ns                          = undef,
  $ipaddress                   = $::ipaddress,
  $port                        = $::openiosds::params::ecd_port,
  $documentRoot                = undef,
  $serverRoot                  = undef,
  $checks                      = undef,
  $stats                       = undef,
  $serverName                  = 'localhost',
  $serverSignature             = 'Off',
  $serverTokens                = 'Prod',
  $prefork_MaxClients          = '150',
  $prefork_StartServers        = '5',
  $prefork_MinSpareServers     = '5',
  $prefork_MaxSpareServers     = '10',
  $worker_StartServers         = '5',
  $worker_MaxClients           = '100',
  $worker_MinSpareThreads      = '5',
  $worker_MaxSpareThreads      = '25',
  $worker_ThreadsPerChild      = '10',
  $worker_MaxRequestsPerChild  = '0',
  $wSGIDaemonProcess_processes = '2',
  $wSGIDaemonProcess_threads   = '1',

  $location                   = $hostname,
  $slots                      = undef,
  $no_exec                    = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Validation
  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("${ipaddress} is invalid.") }
  validate_integer($port)
  if $documentRoot { $_documentRoot = $documentRoot }
  else { $_documentRoot = "${openiosds::sharedstatedir}/${ns}/${type}-${num}" }
  if $serverRoot { $_serverRoot = $serverRoot }
  else { $_serverRoot = "${openiosds::sharedstatedir}/${ns}/coredump" }
  if $checks { $_checks = $checks }
  else { $_checks = ['{type: http, uri: /info}'] }
  if $stats { $_stats = $stats }
  else { $_stats = ["{type: volume, path: ${_documentRoot}}",'{type: ecd, path: /stat}','{type: system}'] }
  validate_string($serverName)
  validate_string($serverSignature)
  validate_string($serverTokens)
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
  if $slots { validate_array($slots) }

  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Packages
  ensure_packages([$::openiosds::httpd_package_name,$::openiosds::httpd_wsgi_package_name],$::openiosds::params::package_install_options)
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
    content => template('openiosds/wsgi-httpd.conf.erb'),
    mode    => $openiosds::file_mode,
    require => Package[$::openiosds::httpd_package_name],
  } ->
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.wsgi":
    ensure  => $openiosds::file_ensure,
    content => template('openiosds/ecd.wsgi.erb'),
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

}
