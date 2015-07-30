define openiosds::sdsagent (
  $action  = 'create',
  $type    = 'sds-agent',
  $num     = '0',

  $port    = '4000',

  $no_exec = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  if type($num) != 'integer' { fail("${num} is not an integer.") }

  if type($port) != 'integer' { fail("$port is not an integer.") }

  validate_bool($no_exec)
 

  if $action == 'create' {
    file { "${openiosds::sysconfdir_global}/sds.conf":
      ensure  => $openiosds::file_ensure,
      replace => false,
      content => template("openiosds/sds.conf.erb"),
      owner   => $openiosds::user,
      group   => $openiosds::group,
      mode    => $openiosds::file_mode,
    }
  }

  # Service
  openiosds::service {"${type}-${num}":
    action => $action,
    type   => $type,
    num    => $num,
  } ->
  # Files
  file { "${openiosds::sysconfdir}/${type}-${num}/${type}-${num}.conf":
    ensure => $openiosds::file_ensure,
    content => template("openiosds/${type}.conf.erb"),
    owner   => $openiosds::user,
    group   => $openiosds::group,
    mode    => $openiosds::file_mode,
    notify => Gridinit::Program["${type}-${num}"],
    require => Openiosds::Service["${type}-${num}"],
  } ->
  file { "${openiosds::sysconfdir}/${type}-${num}/${type}-${num}.log4crc":
    ensure => $file_ensure,
    content => template("openiosds/log4crc.erb"),
    owner   => $openiosds::user,
    group   => $openiosds::group,
    mode    => $openiosds::file_mode,
    notify => Gridinit::Program["${type}-${num}"],
    require => Openiosds::Service["${type}-${num}"],
  } ->
  # Init
  gridinit::program { "${type}-${num}":
    command => "${openiosds::bindir}/oio-cluster-agent --child-req -s OIO,local,${type},${num} ${openiosds::sysconfdir}/${type}-${num}/${type}-${num}.conf", 
    group => "${type}",
    uid => $openiosds::user,
    gid => $openiosds::group,
    no_exec => $no_exec,
  }

}
