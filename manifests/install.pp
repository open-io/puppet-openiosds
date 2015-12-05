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
  package { $openiosds::package_names:
    ensure          => $openiosds::package_ensure,
    allow_virtual   => false,
    install_options => $package_install_options,
  }

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
