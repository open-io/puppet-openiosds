# Configure and install an OpenIO oioblobindexer service
define openiosds::oioblobindexer (
  $action            = 'create',
  $type              = 'oio-blob-indexer',
  $num               = '0',

  $ns                = undef,
  $volume            = "${openiosds::sharedstatedir}/${ns}/rawx-${num}",
  $report_interval   = '5',
  $chunks_per_second = '2',

  $no_exec           = false,
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
  if $volume { $_volume = $volume }
  else { $_volume = "${openiosds::sharedstatedir}/${ns}/rawx-${num}" }
  if type3x($report_interval) != 'integer' { fail("${report_interval} is not an integer.") }
  if type3x($chunks_per_second) != 'integer' { fail("${chunks_per_second} is not an integer.") }

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
    mode    => $openiosds::file_mode,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/${type} ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}.conf",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }

}
