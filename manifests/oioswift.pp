# Configure and install an OpenIO oioswift service
define openiosds::oioswift (
  $action                   = 'create',
  $type                     = 'oioswift',
  $num                      = '0',

  $ns                       = undef,
  $ipaddress                = $::ipaddress,
  $port                     = $::openiosds::params::oioswift_port,
  $use_stderr               = 'False',
  $workers                  = '2',
  $sds_proxy_url            = "http://${::openiosds::params::oioproxy_url}",
  $object_post_as_copy      = false,
  $memcache_servers         = "${ipaddress}:11211",
  $memcache_max_connections = 2,
  $memcache_secret_key      = 'memcache_secret_key',
  $auth_uri                 = "http://${ipaddress}:5000",
  $auth_url                 = "http://${ipaddress}:35357",
  $region_name              = 'RegionOne',
  $project_domain_id        = 'default',
  $user_domain_id           = 'default',
  $project_name             = 'service',
  $username                 = 'swift',
  $password                 = 'SWIFT_PASS',
  $delay_auth_decision      = true,
  $operator_roles           = 'admin,swiftoperator',
  $access_log_headers       = false,
  $access_log_headers_only  = undef,
  $auth_system              = 'keystone',
  $log_facility             = '/dev/log',
  $log_level                = 'INFO',
  $eventlet_debug           = false,
  $sds_default_account      = 'default',
  $sds_connection_timeout   = 2,
  $sds_read_timeout         = 5,
  $sds_write_timeout        = 5,
  $sds_pool_connections     = 10,
  $sds_pool_maxsize         = 10,
  $sds_max_retries          = 0,
  $tempauth_users           = [],
  $middleware_swift3          = {'location' => 'RegionOne'},
  $oio_storage_policies       = undef,
  $auto_storage_policies      = undef,
  $middleware_hashedcontainer = undef,
  $middleware_regexcontainer  = undef,
  $middleware_gatekeeper      = {},
  $middleware_healthcheck     = {},

  $no_exec                 = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  validate_integer($num)
  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("${ipaddress} is invalid.") }
  validate_integer($port)
  validate_integer($workers)
  validate_string($sds_proxy_url)
  validate_bool($object_post_as_copy)
  validate_string($memcache_servers)
  validate_integer($memcache_max_connections)
  validate_string($auth_uri)
  validate_string($auth_url)
  validate_bool($delay_auth_decision)
  validate_string($operator_roles)
  validate_bool($access_log_headers)
  if $access_log_headers_only { validate_string($access_log_headers_only) }
  validate_string($auth_system)
  validate_string($log_facility)
  validate_bool($eventlet_debug)
  validate_string($sds_default_account)
  validate_integer($sds_connection_timeout)
  validate_integer($sds_read_timeout)
  validate_integer($sds_write_timeout)
  validate_integer($sds_pool_connections)
  validate_integer($sds_pool_maxsize)
  validate_integer($sds_pool_maxsize)
  validate_array($tempauth_users)

  # Auth system
  case $auth_system {
    'keystone': { $auth_filter = 'keystoneauth' }
    'tempauth': { $auth_filter = 'tempauth proxy-logging' }
    'noauth': { $auth_filter = '' }
    default: { fail("Authentication system ${auth_filter} not supported.") }
  }

  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Packages
  if $::os['family'] == 'RedHat' {
    if $::os['name'] == 'RedHat' {
      if ! defined(Package[basename($::openiosds::params::package_openstack_release,'.rpm')]) {
        ensure_resource('package', basename($::openiosds::params::package_openstack_release,'.rpm'), {
          source   => $::openiosds::params::package_rdo_release,
          provider => 'rpm',
          ensure   => present,
          before   => Package[$::openiosds::params::package_swift_proxy],
        })
      }
    }
    else {
      if ($::openiosds::params::package_openstack_release) and (! defined(Package[$::openiosds::params::package_openstack_release])) {
        ensure_resource('package', $::openiosds::params::package_openstack_release, {
          ensure   => present,
          before   => Package[$::openiosds::params::package_swift_proxy],
        })
      }
    }
  }
  if ! defined(Package[$::openiosds::params::package_swift_proxy]) {
    if $::openiosds::params::package_swift_dep { ensure_packages($::openiosds::params::package_swift_dep,
      $::openiosds::params::package_swift_dep_opt) }
    ensure_resource('package', $::openiosds::params::package_swift_proxy, {
      ensure  => present,
      before  => Package['openio-sds-swift'],
    })
  }
  ensure_packages('openio-sds-swift',$::openiosds::params::package_install_options)
  # Service
  openiosds::service {"${ns}-${type}-${num}":
    action => $action,
    type   => $type,
    num    => $num,
    ns     => $ns,
  }
  # Configuration files
  -> file { '/etc/swift/swift.conf':
    mode => '0644',
  }
  -> file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/proxy-server.conf":
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}-proxy-server.conf.erb"),
    mode    => $openiosds::file_mode,
  }
  # Init
  -> gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/swift-proxy-server  ${openiosds::sysconfdir}/${ns}/${type}-${num}/proxy-server.conf",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
