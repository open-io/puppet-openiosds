# == Class: openiosds
#
# === Authors
#
# Romain Acciari <romain.acciari@openio.io>
#
# === Copyright
#
# Copyright 2015      OpenIO
#

class openiosds(
  $project_name             = $openiosds::params::project_name,
  $prefixdir                = $openiosds::params::prefixdir,
  $libdir                   = $openiosds::params::libdir,
  $bindir                   = $openiosds::params::bindir,
  $sysconfdir_global        = $openiosds::params::sysconfdir_global,
  $sysconfdir_globald       = $openiosds::params::sysconfdir_globald,
  $sysconfdir               = $openiosds::params::sysconfdir,
  $localstatedir            = $openiosds::params::localstatedir,
  $runstatedir              = $openiosds::params::runstatedir,
  $spoolstatedir_global     = $openiosds::params::spoolstatedir_global,
  $spoolstatedir            = $openiosds::params::spoolstatedir,
  $sharedstatedir_global    = $openiosds::params::sharedstatedir_global,
  $sharedstatedir           = $openiosds::params::sharedstatedir,
  $logdir_global            = $openiosds::params::logdir,
  $logdir                   = $openiosds::params::logdir,
  $globaldirs               = $openiosds::params::globaldirs,
  $user                     = $openiosds::params::user,
  $user_ensure              = $openiosds::params::user_ensure,
  $uid                      = $openiosds::params::uid,
  $group                    = $openiosds::params::group,
  $group_ensure             = $openiosds::params::group_ensure,
  $gid                      = $openiosds::params::gid,
  $package_ensure           = $openiosds::params::package_ensure,
  $package_names            = $openiosds::params::package_names,
  $logfile_maxbytes         = $openiosds::params::logfile_maxbytes,
  $logfile_backups          = $openiosds::params::logfile_backups,
  $log_level                = $openiosds::params::log_level,
  $service_ensure           = $openiosds::params::service_ensure,
  $server_ipaddress         = $openiosds::params::server_ipaddress,
  $conscience_port          = $openiosds::params::conscience_port,
  $meta0_port               = $openiosds::params::conscience_port,
  $meta1_port               = $openiosds::params::meta1_port,
  $meta2_port               = $openiosds::params::meta2_port,
  $rawx_port                = $openiosds::params::rawx_port,
  $rdir_port                = $openiosds::params::rdir_port,
  $sqlx_port                = $openiosds::params::sqlx_port,
  $zookeeper_port           = $openiosds::params::zookeeper_port,
  $account_port             = $openiosds::params::account_port,
  $redis_port               = $openiosds::params::redis_port,
  $redissentinel_port       = $openiosds::params::redissentinel_port,
  $oioswift_port            = $openiosds::params::oioswift_port,
  $oioproxy_port            = $openiosds::params::oioproxy_port,
  $conscience_url           = $openiosds::params::conscience_url,
  $zookeeper_url            = $openiosds::params::zookeeper_url,
  $oioproxy_url             = $openiosds::params::oioproxy_url,
  $action                   = $openiosds::params::action,
  $namespace                = $openiosds::params::namespace,
  $file_mode                = $openiosds::params::file_mode,
  $file_ensure              = $openiosds::params::file_ensure,
  $data_directory_mode      = $openiosds::params::data_directory_mode,
  $directory_mode           = $openiosds::params::directory_mode,
  $directory_ensure         = $openiosds::params::directory_ensure,
  $no_exec                  = $openiosds::params::no_exec,

  $consciences              = {},
  $meta0s                   = {},
  $meta1s                   = {},
  $meta2s                   = {},
  $rawxs                    = {},
) inherits openiosds::params {

  # Validation
  validate_string($project_name)
  validate_absolute_path($prefixdir)
  validate_absolute_path($libdir)
  validate_absolute_path($bindir)
  validate_absolute_path($sysconfdir_global)
  validate_absolute_path($sysconfdir_globald)
  validate_absolute_path($sysconfdir)
  validate_absolute_path($localstatedir)
  validate_absolute_path($runstatedir)
  validate_absolute_path($spoolstatedir_global)
  validate_absolute_path($spoolstatedir)
  validate_absolute_path($sharedstatedir_global)
  validate_absolute_path($sharedstatedir)
  validate_absolute_path($logdir_global)
  validate_absolute_path($logdir)
#  validate_absolute_path($globaldirs)
  validate_string($user)
  $valid_user_ensure = ['present','absent','role']
  validate_re($user_ensure,$valid_user_ensure,"${user_ensure} is invalid.")
  validate_integer($uid)
  validate_string($group)
  $valid_group_ensure = ['present','absent']
  validate_re($group_ensure,$valid_group_ensure,"${group_ensure} is invalid.")
  validate_integer($gid)
  $valid_package_ensure = ['present','installed','absent','purged','held','latest']
  validate_re($package_ensure,$valid_package_ensure,"${package_ensure} is invalid.")
  validate_array($package_names)
  $valid_log_levels = ['^critical$', '^error$', '^warn$', '^info$', '^debug$', '^trace$', '^blather$']
  validate_re($log_level, $valid_log_levels, "${log_level} is invalid.")
  validate_bool($no_exec)

  validate_hash($consciences)
  validate_hash($meta0s)
  validate_hash($meta1s)
  validate_hash($meta2s)
  validate_hash($rawxs)


  create_resources('openiosds::conscience',$consciences)
  create_resources('openiosds::meta0s',$meta0s)
  create_resources('openiosds::meta1s',$meta1s)
  create_resources('openiosds::meta2s',$meta2s)
  create_resources('openiosds::rawxs',$rawxs)

  contain openiosds::install

}
