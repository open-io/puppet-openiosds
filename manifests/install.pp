class openiosds::install inherits openiosds {
   # User
  user { $openiosds::user:
    ensure => $openiosds::user_ensure,
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
    ensure   => $openiosds::package_ensure,
    provider => $openiosds::package_provider,
    allow_virtual => false,
  } 

  # Path
  file { $globaldirs:
    ensure => $openiosds::directory_ensure,
    owner => $openiosds::user,
    group => $openiosds::group,
    mode => $openiosds::directory_mode,
  }

  file { $sharedstatedir_global:
    ensure => $openiosds::directory_ensure,
    owner => $openiosds::user,
    group => $openiosds::group,
    mode => $openiosds::data_directory_mode,
  }

}