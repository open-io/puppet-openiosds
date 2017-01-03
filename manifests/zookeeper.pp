# Configure and install an OpenIO zookeeper service
define openiosds::zookeeper (
  $action                    = 'create',
  $type                      = 'zookeeper',
  $num                       = '0',

  $ns                        = undef,
  $ipaddress                 = $::ipaddress,
  $port                      = $::openiosds::params::zookeeper_port,
  $tickTime                  = '2000',
  $initLimit                 = '10',
  $syncLimit                 = '5',
  $maxClientCnxns            = '200',
  $servers                   = undef,
  $autopurge_snapretaincount = '3',
  $autopurge_purgeinterval   = '1',
  $bootstrap                 = false,
  $myid                      = undef,
  $dataDir                   = undef,
  $logdir                    = undef,
  $logprop                   = 'INFO,ROLLINGFILE',
  $logMaxFileSize            = '10MB',
  $java_args                 = undef,

  $no_exec                   = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # OS dependent parameters
  case $::osfamily {
    'Debian': {
      $classpath = '/etc/zookeeper/conf:/usr/share/java/jline.jar:/usr/share/java/log4j-1.2.jar:/usr/share/java/xercesImpl.jar:/usr/share/java/xmlParserAPIs.jar:/usr/share/java/netty.jar:/usr/share/java/slf4j-api.jar:/usr/share/java/slf4j-log4j12.jar:/usr/share/java/zookeeper.jar'
      $packages = ['zookeeperd','python-zookeeper']
    }
    'RedHat': {
      case $::operatingsystem {
        'Fedora': {
          $packages = ['zookeeper','java-1.8.0-openjdk-headless','python-zookeeper']
        }
        default: {
          $classpath = '/usr/share/zookeeper/*'
          $packages = ['zookeeper','java-1.8.0-openjdk-headless','python-ZooKeeper']
        }
      }
    }
  }

  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  validate_integer($num)

  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("${ipaddress} is invalid.") }
  validate_integer($port)

  if $servers {
    if is_string($servers) { $servers_array = split($servers,'[;,]') }
    elsif is_array($servers) { $servers_array = $servers }
    else { fail("${servers} is not an array.") }
    $sindex = array_index($servers_array,$ipaddress)
  }
  validate_integer($autopurge_snapretaincount)
  validate_integer($autopurge_purgeinterval)
  if $myid {
    $_myid = $myid
  }
  elsif $sindex {
    $_myid = $sindex
  }
  if $_myid {
    validate_integer($_myid,255,1)
  }
  if $dataDir {
    $_dataDir = $dataDir
    $rootDir = dirname($_dataDir)
  } else {
    $_dataDir = "${openiosds::sharedstatedir}/${ns}/${type}-${num}/data"
    $rootDir = "${openiosds::sharedstatedir}/${ns}/${type}-${num}"
  }
  if $logdir { $_logdir = $logdir }
  else { $_logdir = "${openiosds::logdir}/${ns}/${type}-${num}" }
  validate_string($logprop)
  validate_string($logMaxFileSize)
  if $java_args {
    $_java_args = $java_args
  } else {
    # Default Java args
    if to_i($::memorysize_mb) > 4000 {
      if ($::memorysize_mb / 2) > 8192 {
        $_memorysize_mb = 8192
      }
      else {
        $_memorysize_mb = to_i($::memorysize_mb / 2)
      }
      $_java_mem = "-Xms${_memorysize_mb}M -Xmx${_memorysize_mb}"
    }
    if to_i($::processorcount) > 20 {
      $_java_pgcthreads = '-XX:ParallelGCThreads=8'
    }
    $_java_args = "${_memorysize_mb} -XX:+UseParallelGC ${_java_pgcthreads} -Djute.maxbuffer=8388608"
  }

  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Packages
  # openjdk mandatory for zookeeper. gcj is bullhsit
  #ensure_packages($packages,merge($::openiosds::params::package_install_options,{before=>Openiosds::Service["${ns}-${type}-${num}"]}))
  ensure_packages($packages)
  # Service
  openiosds::service {"${ns}-${type}-${num}":
    action => $action,
    type   => $type,
    num    => $num,
    ns     => $ns,
    volume => $rootDir,
  } ->
  # Data path
  file { $_dataDir:
    ensure  => $openiosds::directory_ensure,
    owner   => $openiosds::user,
    group   => $openiosds::group,
    mode    => $openiosds::directory_mode,
    require => Openiosds::Service["${ns}-${type}-${num}"]
  }
  # Configuration files
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/zoo.cfg":
    ensure  => $openiosds::file_ensure,
    owner   => $openiosds::user,
    group   => $openiosds::group,
    content => template('openiosds/zoo.cfg.erb'),
    require => [Package[$packages],File[$_dataDir]],
    notify  => Gridinit::Program["${ns}-${type}-${num}"],
  }
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/java.env":
    ensure  => $openiosds::file_ensure,
    owner   => $openiosds::user,
    group   => $openiosds::group,
    content => template('openiosds/zookeeper_java.env.erb'),
    require => [Package[$packages],File[$_dataDir]],
    notify  => Gridinit::Program["${ns}-${type}-${num}"],
  }
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/log4j.properties":
    ensure  => $openiosds::file_ensure,
    owner   => $openiosds::user,
    group   => $openiosds::group,
    content => template('openiosds/zookeeper_log4j.properties.erb'),
    require => [Package[$packages],File[$_dataDir]],
    notify  => Gridinit::Program["${ns}-${type}-${num}"],
  }
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "java ${_java_args} -Dzookeeper.log.dir=${_logdir} -Dzookeeper.root.logger=${logprop} -cp ${openiosds::sysconfdir}/${ns}/${type}-${num}:${classpath} -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false org.apache.zookeeper.server.quorum.QuorumPeerMain ${openiosds::sysconfdir}/${ns}/${type}-${num}/zoo.cfg",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
    no_exec => $no_exec,
  }
  # ZooKeeper Bootstrap
  if $bootstrap {
    exec { 'bootstrap':
      command => "/bin/sleep 10 && ${openiosds::bindir}/zk-bootstrap.py ${ns}",
      onlyif  => "/usr/bin/test -r ${openiosds::sysconfdir_globald}/${ns}",
      unless  => "/bin/sleep 3 && echo \"ls /hc/ns/${ns}\" | ${openiosds::bindir}/zkCli.sh -server ${ipaddress}:${port} | grep srv" ,
      require => [Gridinit::Program["${ns}-${type}-${num}"],Openiosds::Namespace[$ns]],
    }
  }
  if $_myid {
    file {"${_dataDir}/myid":
      ensure  => $openiosds::file_ensure,
      owner   => $openiosds::user,
      group   => $openiosds::group,
      content => "$_myid",
    }
  }

}
