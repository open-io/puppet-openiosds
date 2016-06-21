# Configure and install an OpenIO replicator service
define openiosds::replicator (
  $action                     = 'create',
  $type                       = 'replicator',
  $num                        = '0',

  $ns                         = undef,
  $ipaddress                  = $::ipaddress,
  $port                       = $::openiosds::params::replicator_port,
  $source_oioproxy_url        = undef,
  $source_ns                  = undef,
  $destination_oioproxy_url   = undef,
  $destination_ns             = undef,
  $consumer_target            = undef,
  $consumer_queue             = 'oio-repli',

  $location                   = $hostname,
  $no_exec                    = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Validation
  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("${ipaddress} is invalid.") }
  validate_integer($port)
  validate_string($source_oioproxy_url)
  validate_string($source_ns)
  validate_string($destination_oioproxy_url)
  validate_string($destination_ns)
  validate_string($consumer_target)
  validate_string($consumer_queue)
  validate_string($location)

  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Packages
  ensure_packages([$::openiosds::replicator_package_name],$::openiosds::params::package_install_options)
  # Service
  openiosds::service {"${ns}-${type}-${num}":
    action => $action,
    type   => $type,
    num    => $num,
    ns     => $ns,
  } ->
  # Configuration files
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}.conf":
    ensure  => $openiosds::file_ensure,
    content => template('openiosds/replicator.conf.erb'),
    mode    => $openiosds::file_mode,
    require => Package[$::openiosds::replicator_package_name],
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "java -jar /usr/share/java/openio-sds-replicator/openio-sds-replicator-0.1-SNAPSHOT-all.jar ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}.conf",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
