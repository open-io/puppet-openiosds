define openiosds::oioswift (
  $action              = 'create',
  $type                = 'oioswift',
  $num                 = '0',

  $ns                  = undef,
  $ipaddress           = "${ipaddress}",
  $port                = '6007',
  $workers             = '2',
  $oioproxy_url        = "http://${ipaddress}:6006",
  $object_post_as_copy = false,
  $memcache_servers    = "${ipaddress}:11211",
  $auth_uri            = "http://${ipaddress}:5000/v2.0",
  $identity_uri        = "http://10.0.2.15:35357",
  $admin_tenant_name   = "services",
  $admin_user          = "swift",
  $admin_password      = "SWIFT_PASS",
  $delay_auth_decision = "true",

  $conscience_url      = undef,
  $zookeeper_url       = undef,
  $oioproxy_url        = undef,

  $no_exec             = false,
) {

  include openiosds

  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  if type($num) != 'integer' { fail("${num} is not an integer.") }

  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("$ipaddress is invalid.") }
  if type($port) != 'integer' { fail("$port is not an integer.") }
  if type($workers) != 'integer' { fail("$workers is not an integer.") }
  validate_string($oioproxy_url)
  validate_bool($object_post_as_copy)
  validate_string($memcache_servers)


  # Namespace
  if $action == 'create' {
    openiosds::namespace {$ns:
      action         => $action,
      ns             => $ns,
      conscience_url => $conscience_url,
      zookeeper_url  => $zookeeper_url,
      oioproxy_url   => $oioproxy_url,
      eventagent_url => $eventagent_url,
      no_exec        => $no_exec,
    }
  }


  # Packages
  package { 'rdo-release':
    ensure   => present,
    source   => 'https://repos.fedorapeople.org/repos/openstack/openstack-juno/rdo-release-juno-1.noarch.rpm',
    provider => rpm,
    allow_virtual => false,
  } ->
  package { ['openio-sds-swift','openstack-swift-proxy']:
    ensure        => $openiosds::package_ensure,
    provider      => $openiosds::package_provider,
    allow_virtual => false,
  } ->
  # Service
  openiosds::service {"${ns}-${type}-${num}":
    action => $action,
    type   => $type,
    num    => $num,
    ns     => $ns,
  } ->
  # Configuration files
  file { "/etc/swift/swift.conf":
    mode => "0644",
  } ->
  file { "${type}-${num}/proxy-server.conf":
    path    => "${openiosds::sysconfdir}/${ns}/${type}-${num}/proxy-server.conf",
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}-proxy-server.conf.erb"),
    mode    => $openiosds::file_mode,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/swift-proxy-server  ${openiosds::sysconfdir}/${ns}/${type}-${num}/proxy-server.conf",
    group   => "${ns},${type},${type}-${num}",
    uid => $openiosds::user,
    gid => $openiosds::group,
    no_exec => $no_exec,
  }

}
