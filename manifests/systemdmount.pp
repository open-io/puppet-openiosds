# Configure mountpoints
define openiosds::systemdmount (
  $device         = undef,
  $mountpoint     = undef,
  $fstype         = 'xfs',
  $fsoptions      = 'defaults,noatime,noexec',
  $after          = undef,
) {

  # Validation
  validate_string($device)
  validate_string($mountpoint)
  validate_string($fstype)
  validate_string($fsoptions)
  if $after { validate_string($after) }

  $mountpoint_name = systemd_escape($mountpoint)

  # Configuration file
  exec { "mkdir_p_${device}":
    command => "/usr/bin/mkdir -p \'${device}\'",
    unless  => "/usr/bin/test -e \'${device}\'",
  } ->
  exec { "mkdir_p_${mountpoint}":
    command => "/usr/bin/mkdir -p \'${mountpoint}\'",
    unless  => "/usr/bin/test -d \'${mountpoint}\'",
  } ->
  file { $mountpoint:
    ensure => directory,
    mode   => '0755',
  } ->
  file { "/etc/systemd/system/${mountpoint_name}":
    ensure  => present,
    content => template('openiosds/systemd.mount.conf.erb'),
    mode    => '0644',
  }
  service { $mountpoint_name:
    ensure  => running,
    require => File["/etc/systemd/system/${mountpoint_name}"],
  }

}
