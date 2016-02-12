# Configure and install an OpenIO rawx service
define openiosds::rawx (
  $action                 = 'create',
  $type                   = 'rawx',
  $num                    = '0',

  $ns                     = undef,
  $ipaddress              = $::ipaddress,
  $port                   = '6004',
  $default_oioblobindexer = false,
  $documentRoot           = undef,
  $serverRoot             = undef,
  $grid_hash_width        = '3',
  $grid_hash_depth        = '1',
  $checks                 = undef,
  $stats                  = undef,

  $no_exec                = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Validation
  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("${ipaddress} is invalid.") }
  if type3x($port) != 'integer' { fail("${port} is not an integer.") }
  validate_bool($default_oioblobindexer)
  if $documentRoot { $_documentRoot = $documentRoot }
  else { $_documentRoot = "${openiosds::sharedstatedir}/${ns}/${type}-${num}" }
  if $serverRoot { $_serverRoot = $serverRoot }
  else { $_serverRoot = "${openiosds::sharedstatedir}/${ns}/coredump" }
  if type3x($grid_hash_width) != 'integer' { fail("${grid_hash_width} is not an integer.") }
  if type3x($grid_hash_depth) != 'integer' { fail("${grid_hash_depth} is not an integer.") }
  if $checks { $_checks = $checks }
  else { $_checks = ['{type: http, uri: /info}','{type: tcp}'] }
  if $stats { $_stats = $stats }
  else { $_stats = ["{type: volume, path: ${_documentRoot}}",'{type: rawx, path: /stat}','{type: system}'] }

  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Packages
  ensure_packages([$::openiosds::httpd_package_name])
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
    content => template("openiosds/${type}-httpd.conf.erb"),
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
  if $default_oioblobindexer {
    openiosds::oioblobindexer { "oio-blob-indexer-${num}":
      num       => $num,
      ns        => $ns,
      no_exec   => $no_exec,
#     require   => Gridinit::Program["${ns}-${type}-${num}"],
    }
  }
  if $documentRoot {
    file { $documentRoot:
      ensure  => $openiosds::directory_ensure,
      owner   => $openiosds::user,
      group   => $openiosds::group,
      mode    => $openiosds::file_mode,
      before  => File["${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-httpd.conf"],
    }
  }

}
