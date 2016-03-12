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
          case $::operatingsystemrelease {
            '21': {$classpath = '/usr/share/java/log4j12-1.2.17.jar:/usr/share/java/zookeeper/zookeeper.jar:/usr/share/java/slf4j/slf4j-simple.jar:/usr/share/java/slf4j/api.jar:/usr/share/java/slf4j/nop.jar:/usr/share/java/slf4j/slf4j-api.jar:/usr/share/java/slf4j/slf4j-nop.jar:/usr/share/java/slf4j/simple.jar:/usr/share/java/slf4j/slf4j-api.jar:/usr/lib/java/jline1/jline-1.0.jar:/usr/share/java/netty3-3.6.6.jar'}
            default: {
                $classpath = '/usr/share/zookeeper/log4j-1.2.16.jar:/usr/share/zookeeper/netty-3.7.0.Final.jar:/usr/share/zookeeper/slf4j-api-1.6.1.jar:/usr/share/zookeeper/slf4j-log4j12-1.6.1.jar:/usr/share/zookeeper/zookeeper-3.4.8.jar'
            }
          }
          $packages = ['zookeeper','java-1.8.0-openjdk-headless','python-zookeeper']
        }
        default: {
          $classpath = '/usr/share/zookeeper/log4j-1.2.16.jar:/usr/share/zookeeper/netty-3.7.0.Final.jar:/usr/share/zookeeper/slf4j-api-1.6.1.jar:/usr/share/zookeeper/slf4j-log4j12-1.6.1.jar:/usr/share/zookeeper/zookeeper-3.4.8.jar'
          $packages = ['zookeeper','java-1.8.0-openjdk-headless','python-ZooKeeper']
        }
      }
    }
  }

  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  if type3x($num) != 'integer' { fail("${num} is not an integer.") }

  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("${ipaddress} is invalid.") }
  if type3x($port) != 'integer' { fail("${port} is not an integer.") }

  if $servers {
    if is_string($servers) { $servers_array = split($servers,'[;,]') }
    elsif is_array($servers) { $servers_array = $servers }
    else { fail("${servers} is not an array.") }
  }
  if type3x($autopurge_snapretaincount) != 'integer' { fail("${autopurge_snapretaincount} is not an integer.") }
  if type3x($autopurge_purgeinterval) != 'integer' { fail("${autopurge_purgeinterval} is not an integer.") }
  if $myid and (type3x($myid) != 'integer') { fail("${myid} is not an integer.") }
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

  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Packages
  # openjdk mandatory for zookeeper. gcj is bullhsit
  package { $packages:
    ensure        => $openiosds::package_ensure,
    allow_virtual => false,
  } ->
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
    command => "java -Dzookeeper.log.dir=${_logdir} -Dzookeeper.root.logger=${logprop} -cp ${openiosds::sysconfdir}/${ns}/${type}-${num}:${classpath} -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false org.apache.zookeeper.server.quorum.QuorumPeerMain ${openiosds::sysconfdir}/${ns}/${type}-${num}/zoo.cfg",
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
  if $myid {
    file {"${openiosds::sharedstatedir}/${ns}/${type}-${num}/data/myid":
      ensure  => $openiosds::file_ensure,
      owner   => $openiosds::user,
      group   => $openiosds::group,
      content => $myid,
    }
  }

}
