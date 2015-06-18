define openiosds::elasticsearch (
  $action                   = 'create',
  $type                     = 'elasticsearch',
  $num                      = '0',

  $ns                       = undef,
  $bind_host                = undef,
  $publish_host             = undef,
  $host                     = undef,
  $tcp_port                 = '9300',
  $http_port                = '9200',
  $es_homedir               = '/usr/share/elasticsearch',
  $discovery_mode           = 'redcurrant',
  $environment              = {'ES_MIN_MEM' => '1g', 'ES_MAX_MEM' => '1g'},
  $node_master              = false,
  $node_data                = true,
  $index_number_of_shards   = '5',
  $index_number_of_replicas = '1',
  $bootstrap_mlockall       = true,
  $unicast_hosts            = undef,
  $conscience_ipaddress     = undef,
  $conscience_port          = undef,

  $no_exec                  = false,
) {

  include openiosds


  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  if type($num) != 'integer' { fail("${num} is not an integer.") }

  validate_string($ns)
  if $bind_host and ! has_interface_with('ipaddress',$bind_host) { fail("$bind_host is invalid.") }
  if $publish_host and ! has_interface_with('ipaddress',$publish_host) { fail("$publish_host is invalid.") }
  if $host and ! has_interface_with('ipaddress',$host) { fail("$host is invalid.") }
  if type($tcp_port) != 'integer' { fail("$tcp_port is not an integer.") }
  if type($http_port) != 'integer' { fail("$http_port is not an integer.") }
  validate_absolute_path($es_homedir)
  $valid_discovery_modes = ['multicast','unicast','redcurrant']
  validate_re($discovery_mode, $valid_discovery_modes, "${discovery_mode} is invalid.")
  validate_hash($environment)
  validate_bool($node_master)
  validate_bool($node_data)
  if type($index_number_of_shards) != 'integer' { fail("$index_number_of_shards is not an integer.") }
  if type($index_number_of_replicas) != 'integer' { fail("$index_number_of_replicas is not an integer.") }
  validate_bool($bootstrap_mlockall)
  if $discovery_mode == 'unicast' { validate($unicast_hosts) }
  validate_string($conscience_ipaddress)
  if type($conscience_port) != 'integer' { fail("$conscience_port is not an integer.") }
  

  # Configuration files
  file { "${type}-${num}.yml":
    path => "${sysconfdir}/${type}-${num}/${type}.yml",
    ensure => $file_ensure,
    content => template("openiosds/${type}.yml.erb"),
    owner => "openio",
    group => "openio",
    mode => "0644",
  } ->
  file { "${type}-${num}.logging.yml":
    path => "${sysconfdir}/${type}-${num}/logging.yml",
    ensure => $file_ensure,
    content => template("openiosds/${type}.logging.yml.erb"),
    owner => "openio",
    group => "openio",
    mode => "0644",
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action      => $action,
    command     => "${es_homedir}/bin/elasticsearch -p ${openiosds::runstatedir}/${ns}-${type}-${num}.pid -Des.default.path.home=${es_homedir} -Des.default.path.conf=${openiosds::sysconfdir}/${ns}/${type}-${num}",
    group       => "${ns},${type},${type}-${num}",
    environment => $environment,
    uid => $openiosds::user,
    gid => $openiosds::group,
    no_exec => $no_exec,
  }

}
