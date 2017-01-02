# Configure user, group, global directories and install base packages
class openiosds::install inherits openiosds {
  # User
  user { $openiosds::user:
    ensure  => $openiosds::user_ensure,
    uid     => $openiosds::uid,
    require => Group[$openiosds::group],
  }
  # Group
  group { $openiosds::group:
    ensure => $openiosds::group_ensure,
    gid    => $openiosds::gid,
  }

  # Packages
  ensure_packages([$::openiosds::package_names],merge($::openiosds::params::package_install_options,{before => [File[$openiosds::globaldirs],File[$openiosds::sharedstatedir_global]]}))

  # Path
  file { $openiosds::globaldirs:
    ensure => $openiosds::directory_ensure,
    owner  => $openiosds::user,
    group  => $openiosds::group,
    mode   => $openiosds::directory_mode,
  }

  file { $openiosds::sharedstatedir_global:
    ensure => $openiosds::directory_ensure,
    owner  => $openiosds::user,
    group  => $openiosds::group,
    mode   => $openiosds::data_directory_mode,
  }

}
