# Class: openiosds::params
#
# Default parameters for openiosds
#
class openiosds::params {
  $project_name             = 'oio'
  $product_name             = 'sds'
  # Path
  $prefixdir                = '/usr'
  case $::os['family'] {
    'Debian': {
      $libdir                  = "${prefixdir}/lib"
      $httpd_daemon            = '/usr/sbin/apache2'
      $httpd_moduledir         = "${libdir}/apache2/modules"
      $httpd_package_name      = ['openio-sds']
      $package_names           = ['openio-sds']
      $package_install_options = '--force-yes'
      $redis_package_name      = 'redis-server'
      $redis_service_name      = 'redis-server'
    }
    'RedHat': {
      case $::architecture {
        'x86_64': { $libdir = "${prefixdir}/lib64" }
        default:  { $libdir = "${prefixdir}/lib" }
      }
      $httpd_daemon            = '/usr/sbin/httpd'
      $httpd_moduledir         = "${libdir}/httpd/modules"
      $httpd_package_name      = ['openio-sds-mod-httpd']
      $package_names           = ['openio-sds-server','openio-sds-rsyslog','openio-sds-logrotate']
      $package_install_options = undef
      $redis_package_name      = 'redis'
      $redis_service_name      = 'redis'
    }
    default: { fail("osfamily ${::osfamily} not supported.") }
  }
  $bindir                   = "${prefixdir}/bin"
  $sysconfdir_global        = "/etc/${project_name}"
  $sysconfdir_globald       = "/etc/${project_name}/${product_name}.conf.d"
  $sysconfdir               = "/etc/${project_name}/${product_name}"
  $runstatedir              = '/run/oio/sds'
  $localstatedir            = '/var'
  $spoolstatedir_global     = "${localstatedir}/spool/${project_name}"
  $spoolstatedir            = "${localstatedir}/spool/${project_name}/${product_name}"
  $sharedstatedir_global    = "${localstatedir}/lib/${project_name}"
  $sharedstatedir           = "${localstatedir}/lib/${project_name}/${product_name}"
  $logdir_global            = "${localstatedir}/log/${project_name}"
  $logdir                   = "${localstatedir}/log/${project_name}/${product_name}"
  $globaldirs               = [$sysconfdir_global,$sysconfdir_globald,$spoolstatedir_global,$logdir_global]
  # Administration
  $user                     = 'openio'
  $user_ensure              = 'present'
  $uid                      = '120'
  $group                    = 'openio'
  $group_ensure             = 'present'
  $gid                      = '220'
  # Packages
  $package_ensure           = 'installed'
  # Logging
  $logfile_maxbytes         = '50MB'
  $logfile_backups          = '14'
  $log_level                = 'info'
  # Services
  $service_ensure           = 'running'
  $server_ipaddress         = $::ipaddress
  $conscience_port          = '6000'
  $meta0_port               = '6001'
  $meta1_port               = '6002'
  $meta2_port               = '6003'
  $rawx_port                = '6004'
  $zookeeper_port           = '6005'
  $oioproxy_port            = '6006'
  $oioswift_port            = '6007'
  $oioeventagent_port       = '6008'
  $account_port             = '6009'
  $rdir_port                = '6010'
  $redis_port               = '6011'
  $redissentinel_port       = '6012'
  $rainx_port               = '6013'
  $conscience_url           = "${server_ipaddress}:${conscience_port}"
  $zookeeper_url            = "${server_ipaddress}:${zookeeper_port}"
  $oioproxy_url             = "${server_ipaddress}:${oioproxy_port}"
  $action                   = 'create'
  $namespace                = 'DEFAULT_NAMESPACE'
  $num                      = '0'
  # Files & directories
  $file_mode                = '0644'
  $file_ensure              = 'file'
  $data_directory_mode      = '0750'
  $directory_mode           = '0755'
  $directory_ensure         = 'directory'
  $no_exec                  = false
}
