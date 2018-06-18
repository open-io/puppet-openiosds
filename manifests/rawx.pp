# Configure and install an OpenIO rawx service
define openiosds::rawx (
  $action                     = 'create',
  $type                       = 'rawx',
  $num                        = '0',

  $ns                         = undef,
  $ipaddress                  = $::ipaddress,
  $port                       = $::openiosds::params::rawx_port,
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
  $grid_fsync                 = 'enabled',
  $grid_fsync_dir             = 'enabled',
  $httpd_mpm                  = {'worker'=>{'StartServers'=>1,'MinSpareThreads'=>32,'MaxSpareThreads'=>256,'ThreadsPerChild'=>256,'MaxRequestsPerChild'=>0,'ServerLimit'=>16}},

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
  validate_integer($grid_hash_width)
  validate_integer($grid_hash_depth)
  if $checks { $_checks = $checks }
  else { $_checks = ['{type: http, uri: /info}'] }
  if $stats { $_stats = $stats }
  else { $_stats = ["{type: volume, path: ${_documentRoot}}",'{type: rawx, path: /stat}','{type: system}'] }
  validate_string($serverName)
  validate_string($serverSignature)
  validate_string($serverTokens)
  validate_string($typesConfig)
  validate_string($grid_fsync)
  validate_string($grid_fsync_dir)
  validate_integer($grid_hash_width)
  validate_string($location)
  if $slots { validate_array($slots) }

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

}
