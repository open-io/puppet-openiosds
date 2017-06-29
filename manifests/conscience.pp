# Configure and install an OpenIO conscience service
define openiosds::conscience (
  $action                                = 'create',
  $type                                  = 'conscience',
  $num                                   = '0',

  $ns                                    = undef,
  $ipaddress                             = $::ipaddress,
  $port                                  = $::openiosds::params::conscience_port,
  $chunk_size                            = '10485760',
  $ns_status                             = 'STANDALONE',
  $worm                                  = false,
  $auto_container                        = false,
  $vns                                   = undef,
  $storage_policy                        = 'SINGLE',
  $storage_policies                      = {
    'SINGLE'       => 'NONE:NONE',
    'TWOCOPIES'    => 'NONE:DUPONETWO',
    'THREECOPIES'  => 'NONE:DUPONETHREE',
    'ERASURECODE'  => 'NONE:ERASURECODE',
    'ECLIBEC63D1'  => 'NONE:ECLIBEC63D1',
    'ECLIBEC144D1' => 'NONE:ECLIBEC144D1',
    'ECISAL63D1'   => 'NONE:ECISAL63D1',
    'ECISAL144D1'  => 'NONE:ECISAL144D1'},
  $data_security                         = {
    'DUPONETWO'    => 'plain/distance=1,nb_copy=2',
    'DUPONETHREE'  => 'plain/distance=1,nb_copy=3',
    'ERASURECODE'  => 'ec/k=6,m=3,algo=liberasurecode_rs_vand,distance=1',
    'ECLIBEC63D1'  => 'ec/k=6,m=3,algo=liberasurecode_rs_vand,distance=1',
    'ECLIBEC123D1' => 'ec/k=12,m=3,algo=liberasurecode_rs_vand,distance=1',
    'ECLIBEC144D1' => 'ec/k=14,m=4,algo=liberasurecode_rs_vand,distance=1',
    'ECISAL63D1'   => 'ec/k=6,m=3,algo=isa_l_rs_vand,distance=1',
    'ECISAL123D1'  => 'ec/k=12,m=3,algo=isa_l_rs_vand,distance=1'},
    'ECISAL144D1'  => 'ec/k=14,m=4,algo=isa_l_rs_vand,distance=1'},
  $service_update_policy                 = {
    'meta2' => 'KEEP|1|1|',
    'sqlx'  => 'KEEP|1|1|',
    'rdir'  => 'KEEP|1|1|user_is_a_service=rawx'},
  $pools                                 = {},
  $score_lock_at_first_register          = {},
  $services_score_timeout                = {
    'meta0'   => '3600',
    'meta1'   => '120',
    'meta2'   => '120',
    'rawx'    => '120',
    'sqlx'    => '120',
    'rdir'    => '120',
    'redis'   => '120',
    'oiofs'   => '120',
    'account' => '120'},
  $services_score_expr                   = {
    'meta0'   => 'root(2,((num stat.cpu)*((num stat.io)+1)))',
    'meta1'   => '((num stat.space)>=5) * root(3,(((num stat.cpu)+1)*(num stat.space)*((num stat.io)+1)))',
    'meta2'   => '((num stat.space)>=5) * root(3,(((num stat.cpu)+1)*(num stat.space)*((num stat.io)+1)))',
    'rawx'    => '(num tag.up) * ((num stat.space)>=5) * root(3,(((num stat.cpu)+1)*(num stat.space)*((num stat.io)+1)))',
    'sqlx'    => '((num stat.space)>=5) * root(3,(((num stat.cpu)+1)*(num stat.space)*((num stat.io)+1)))',
    'rdir'    => '(num tag.up) * ((num stat.cpu)+1) * ((num stat.space)>=2)',
    'redis'   => '(num tag.up) * ((num stat.cpu)+1)',
    'oiofs'   => '((num stat.cpu)+1)',
    'account' => '(num tag.up) * ((num stat.cpu)+1)'},
  $automatic_open                        = true,
  $meta2_max_versions                    = '1',
  $min_workers                           = '2',
  $min_spare_workers                     = '2',
  $max_spare_workers                     = '10',
  $max_workers                           = '10',
  $score_timeout                         = '86400',
  $lb_rawx                               = 'WRAND',
  $lb_rdir                               = 'WRAND?shorten_ratio=1.0&standard_deviation=no',
  $param_option_events_max_pending       = '1000',
  $param_option_meta2_events_max_pending = '1000',
  $param_option_meta1_events_max_pending = '1000',
  $flatns                                = false,
  $flatns_options                        = {
    'flat_hash_offset' => 0,
    'flat_hash_size'   => 0,
    'flat_bitlength'   => '17'},

  $no_exec               = false,
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
  validate_integer($chunk_size)
  $valid_ns_status = ['STANDALONE','MASTER','SLAVE']
  validate_re($ns_status,$valid_ns_status,"${ns_status} is invalid.")
  validate_bool($worm)
  validate_bool($auto_container)
  if $vns { validate_string($vns) }
  validate_hash($storage_policies)
  validate_hash($data_security)
  if !has_key($storage_policies, $storage_policy) { fail("${storage_policy} is invalid.") }
  validate_hash($service_update_policy)
  validate_bool($automatic_open)
  validate_integer($meta2_max_versions)
  validate_integer($min_workers)
  validate_integer($min_spare_workers)
  validate_integer($max_spare_workers)
  validate_integer($max_workers)
  validate_integer($score_timeout)
  validate_hash($services_score_timeout)
  validate_hash($services_score_expr)
  validate_integer($param_option_events_max_pending)
  validate_integer($param_option_meta2_events_max_pending)
  validate_integer($param_option_meta1_events_max_pending)
  if $flatns {
    validate_integer($flatns_options['flat_hash_offset'],0,0)
    validate_integer($flatns_options['flat_hash_size'],0,0)
    validate_integer($flatns_options['flat_bitlength'],256,1)
  }


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
  }
  # Configuration files
  -> file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf":
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}.conf.erb"),
    owner   => $openiosds::user,
    group   => $openiosds::group,
    mode    => '0644',
    notify  => Gridinit::Program["${ns}-${type}-${num}"],
    require => Class['openiosds'],
  }
  -> file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-policies.conf":
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}.storage.erb"),
    owner   => $openiosds::user,
    group   => $openiosds::group,
    mode    => '0644',
    notify  => Gridinit::Program["${ns}-${type}-${num}"],
  }
  -> file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-services.conf":
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}.services.erb"),
    owner   => $openiosds::user,
    group   => $openiosds::group,
    mode    => '0644',
    notify  => Gridinit::Program["${ns}-${type}-${num}"],
  }
  # Init
  -> gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/oio-daemon -s OIO,${ns},${type},${num} ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
