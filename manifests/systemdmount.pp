# Configure mountpoints
define openiosds::systemdmount (
  $uuid           = undef,
  $mountpoint     = undef,
  $fstype         = 'xfs',
  $fsoptions      = 'defaults,noatime,noexec',
) {

  # Validation
#  validate_string($uuid)
#  validate_string($mountpoint)
#  validate_string($fstype)
#  validate_string($fsoptions)

  $mountpoint_sub1 = regsubst($mountpoint, '/', '-', 'G')
  $mountpoint_name = regsubst($mountpoint_sub1, '-', '')

  # Configuration file
  file { "/etc/systemd/system/${mountpoint_name}.mount":
    ensure  => present,
    content => template('openiosds/systemd.mount.conf.erb'),
    mode    => '0644',
  } ->
  file { $mountpoint:
    ensure => directory,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  } ->
  exec { "/usr/bin/systemctl start ${mountpoint_name}.mount":
#    command => "/usr/bin/systemctl start ${mountpoint_name}.mount":
  }

}
