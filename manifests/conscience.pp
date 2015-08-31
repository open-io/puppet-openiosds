define openiosds::conscience (
  $action                = 'create',
  $type                  = 'conscience',
  $num                   = '0',

  $ns                    = undef,
  $ipaddress             = $::ipaddress,
  $port                  = '6000',
  $chunk_size            = '10485760',
  $ns_status             = 'STANDALONE',
  $worm                  = false,
  $auto_container        = false,
  $vns                   = undef,
  $storage_policy        = 'SINGLE',
  $service_update_policy = 'meta2=NONE|1|1|tag.type=m2v2;meta1=REPLACE;sqlx=KEEP|1|1|',
  $automatic_open        = true,
  $meta2_max_versions    = '1',
  $min_workers           = '2',
  $min_spare_workers     = '2',
  $max_spare_workers     = '10',
  $max_workers           = '10',
  $score_timeout         = '86400',

  $no_exec               = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }


  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  if type($num) != 'integer' { fail("${num} is not an integer.") }

  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("$ipaddress is invalid.") }
  if type($port) != 'integer' { fail("$port is not an integer.") }
  if type($chunk_size) != 'integer' { fail("$chunk_size is not an integer.") }
  $valid_ns_status = ['STANDALONE','MASTER','SLAVE']
  validate_re($ns_status,$valid_ns_status,"$ns_status is invalid.")
  validate_bool($worm)
  validate_bool($auto_container)
  if $vns { validate_string($vns) }
  $valid_storage_policy = ['SINGLE','TWOCOPIES','THREECOPIES','FIVECOPIES','RAIN']
  validate_re($storage_policy,$valid_storage_policy,"$storage_policy is invalid.")
  validate_string($service_update_policy)
  validate_bool($automatic_open)
  if type($meta2_max_versions) != 'integer' { fail("$meta2_max_versions is not an integer.") }
  if type($min_workers) != 'integer' { fail("$min_workers is not an integer.") }
  if type($min_spare_workers) != 'integer' { fail("$min_spare_workers is not an integer.") }
  if type($max_spare_workers) != 'integer' { fail("$max_spare_workers is not an integer.") }
  if type($max_workers) != 'integer' { fail("$max_workers is not an integer.") }
  if type($score_timeout) != 'integer' { fail("$score_timeout is not an integer.") }


  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Service
  openiosds::service {"${ns}-${type}-${num}":
    action => $action,
    type   => $type,
    num    => $num,
    ns     => $ns,
  } ->
  # Configuration files
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf":
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}.conf.erb"),
    owner   => $openiosds::user,
    group   => $openiosds::group,
    mode    => "0644",
    notify  => Gridinit::Program["${ns}-${type}-${num}"],
    require => Class['openiosds'],
  } ->
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-events.conf":
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}.events.erb"),
    owner   => $openiosds::user,
    group   => $openiosds::group,
    mode    => "0644",
    notify  => Gridinit::Program["${ns}-${type}-${num}"],
  } ->
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-policies.conf":
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}.storage.erb"),
    owner   => $openiosds::user,
    group   => $openiosds::group,
    mode    => "0644",
    notify  => Gridinit::Program["${ns}-${type}-${num}"],
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/oio-daemon -s OIO,${ns},${type},${num} ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
