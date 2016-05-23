# Configure mountpoints
define openiosds::systemdmount (
  $device                   = undef,
  $mountpoint               = undef,
  $fstype                   = 'xfs',
  $fsoptions                = 'defaults,noatime,noexec',
  $after                    = undef,
  $automount                = true,
  $automount_timeoutidlesec = '20',
  $automount_directorymode  = '0755',
) {

  # Validation
  validate_string($device)
  validate_string($mountpoint)
  validate_string($fstype)
  validate_string($fsoptions)
  if $after { validate_string($after) }
  validate_bool($automount)
  validate_integer($automount_timeoutidlesec)

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
    owner  => 'root',
    group  => 'root',
  } ->
  file { "/etc/systemd/system/${mountpoint_name}.mount":
    ensure  => present,
    content => template('openiosds/systemd.mount.conf.erb'),
    mode    => '0644',
  }
  service { "${mountpoint_name}.mount":
    ensure  => running,
    require => File["/etc/systemd/system/${mountpoint_name}.mount"],
  }

  if $automount {
    file { "/etc/systemd/system/${mountpoint_name}.automount":
      ensure  => present,
      content => template('openiosds/systemd.automount.conf.erb'),
      mode    => '0644',
      require => File["/etc/systemd/system/${mountpoint_name}.mount"],
    }
    service { "${mountpoint_name}.automount":
      enable  => true,
      require => [File["/etc/systemd/system/${mountpoint_name}.automount"],Service["${mountpoint_name}.mount"]],
    }
  }

}
