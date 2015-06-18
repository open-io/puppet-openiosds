define openiosds::rainx (
  $action='create',
  $type='rainx',
  $num='0',
) {

  include openiosds


  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  if type($num) != 'integer' { fail("${num} is not an integer.") }

  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("$ipaddress is invalid.") }
  if type($port) != 'integer' { fail("$port is not an integer.") }


  # Namespace
  if $action == 'create' {
    openiosds::namespace {$ns:
      action         => $action,
      ns             => $ns,
      conscience_url => $conscience_url,
      zookeeper_url  => $zookeeper_url,
    }
  }


  # Packages
  package { 'openio-sds-mod-httpd':
    ensure => installed,
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
    path => "${sysconfdir}/${ns}/${type}-${num}/${type}-${num}-httpd.conf",
    ensure => $openiosds::file_ensure,
    content => template("openiosds/${type}-httpd.conf.erb"),
    owner => $openiosds::user,
    group => $openiosds::group,
  } ->
  file { "${type}-monitor.conf":
    path => "${sysconfdir}/${ns}/${type}-${num}/${type}-${num}-monitor.conf",
    ensure => $file_ensure,
    content => template("openiosds/${type}-monitor.conf.erb"),
    owner => $openiosds::user,
    group => $openiosds::group,
  } ->
  file { "${type}-monitor.log4c":
    path => "${sysconfdir}/${ns}/${type}-${num}/${type}-${num}-monitor.log4crc",
    ensure => $file_ensure,
    content => template("openiosds/log4crc.erb"),
    owner => $openiosds::user,
    group => $openiosds::group,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action => $action,
    command => "${openiosds::bindir}/${type}-monitor.py ${sysconfdir}/${ns}/${type}-${num}/${type}-${num}-monitor.conf ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-monitor.log4crc",
    group => "${ns},${type},${type}-${num}",
    uid => $openiosds::user,
    gid => $openiosds::group,
  }

}
