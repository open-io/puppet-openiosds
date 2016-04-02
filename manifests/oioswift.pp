# Configure and install an OpenIO oioswift service
define openiosds::oioswift (
  $action              = 'create',
  $type                = 'oioswift',
  $num                 = '0',

  $ns                  = undef,
  $ipaddress           = $::ipaddress,
  $port                = $::openiosds::params::oioswift_port,
  $workers             = '2',
  $sds_proxy_url       = "http://${::openiosds::params::oioproxy_url}",
  $object_post_as_copy = false,
  $memcache_servers    = "${ipaddress}:11211",
  $auth_uri            = "http://${ipaddress}:5000/v2.0",
  $auth_protocol       = 'http',
  $auth_host           = $::ipaddress,
  $auth_port           = '35357',
  $identity_uri        = "http://${ipaddress}:35357",
  $admin_tenant_name   = 'services',
  $admin_user          = 'swift',
  $admin_password      = 'SWIFT_PASS',
  $delay_auth_decision = true,
  $operator_roles      = 'admin,_member_',

  $no_exec             = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  if type3x($num) != 'integer' { fail("${num} is not an integer.") }
  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("${ipaddress} is invalid.") }
  if type3x($port) != 'integer' { fail("${port} is not an integer.") }
  if type3x($workers) != 'integer' { fail("${workers} is not an integer.") }
  validate_string($sds_proxy_url)
  validate_bool($object_post_as_copy)
  validate_string($memcache_servers)
  validate_string($auth_uri)
  validate_string($auth_protocol)
  validate_string($auth_host)
  if type3x($auth_port) != 'integer' { fail("${auth_port} is not an integer.") }
  validate_string($identity_uri)
  validate_string($admin_tenant_name)
  validate_string($admin_user)
  validate_string($admin_password)
  validate_bool($delay_auth_decision)
  validate_string($operator_roles)


  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Packages
  if $::os['family'] == 'RedHat' {
    if ! defined(Package[$::openiosds::params::package_rdo_release]) {
      ensure_resource('package', $::openiosds::params::package_rdo_release, {
        ensure  => present,
        before  => Package[$::openiosds::params::package_swift_proxy],
      })
    }
  }
  if ! defined(Package[$::openiosds::params::package_swift_proxy]) {
    ensure_resource('package', $::openiosds::params::package_swift_proxy, {
      ensure  => present,
      before  => Package['openio-sds-swift'],
    })
  }
  ensure_packages('openio-sds-swift')
  # Service
  openiosds::service {"${ns}-${type}-${num}":
    action => $action,
    type   => $type,
    num    => $num,
    ns     => $ns,
  } ->
  # Configuration files
  file { '/etc/swift/swift.conf':
    mode => '0644',
  } ->
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/proxy-server.conf":
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}-proxy-server.conf.erb"),
    mode    => $openiosds::file_mode,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/swift-proxy-server  ${openiosds::sysconfdir}/${ns}/${type}-${num}/proxy-server.conf",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
