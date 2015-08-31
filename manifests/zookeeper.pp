define openiosds::zookeeper (
  $action                    = 'create',
  $type                      = 'zookeeper',
  $num                       = '0',

  $ns                        = undef,
  $ipaddress                 = $::ipaddress,
  $port                      = '6005',
  $tickTime                  = '2000',
  $initLimit                 = '10',
  $syncLimit                 = '5',
  $maxClientCnxns            = '200',
  $servers                   = undef,
  $autopurge_snapretaincount = '3',
  $autopurge_purgeinterval   = '1',
  $bootstrap                 = false,
  $myid                      = undef,

  $no_exec                   = false,
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # OS dependent parameters
  case $::operatingsystem {
    'Fedora': {
      case $::operatingsystemrelease {
        '21': {$classpath = '/usr/share/java/log4j12-1.2.17.jar:/usr/share/java/zookeeper/zookeeper.jar:/usr/share/java/slf4j/slf4j-simple.jar:/usr/share/java/slf4j/api.jar:/usr/share/java/slf4j/nop.jar:/usr/share/java/slf4j/slf4j-api.jar:/usr/share/java/slf4j/slf4j-nop.jar:/usr/share/java/slf4j/simple.jar:/usr/share/java/slf4j/slf4j-api.jar:/usr/lib/java/jline1/jline-1.0.jar:/usr/share/java/netty3-3.6.6.jar'}
        default: {
          $classpath = '/usr/share/zookeeper/log4j-1.2.16.jar:/usr/share/zookeeper/netty-3.7.0.Final.jar:/usr/share/zookeeper/slf4j-api-1.6.1.jar:/usr/share/zookeeper/slf4j-log4j12-1.6.1.jar:/usr/share/zookeeper/zookeeper-3.4.6.jar'
        }
      }
      $packages = ['zookeeper','java-1.8.0-openjdk-headless','python-zookeeper']
    }
    default: {
      $classpath = '/usr/share/zookeeper/log4j-1.2.16.jar:/usr/share/zookeeper/netty-3.7.0.Final.jar:/usr/share/zookeeper/slf4j-api-1.6.1.jar:/usr/share/zookeeper/slf4j-log4j12-1.6.1.jar:/usr/share/zookeeper/zookeeper-3.4.6.jar'
      $packages = ['zookeeper','java-1.7.0-openjdk-headless','python-ZooKeeper']
    }
  }

  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  if type($num) != 'integer' { fail("${num} is not an integer.") }

  validate_string($ns)
  if ! has_interface_with('ipaddress',$ipaddress) { fail("${ipaddress} is invalid.") }
  if type($port) != 'integer' { fail("${port} is not an integer.") }

  if $servers {
    if is_string($servers) { $servers_array = split($servers,'[;,]') }
    elsif is_array($servers) { $servers_array = $servers }
    else { fail("${servers} is not an array.") }
  }
  if type($autopurge_snapretaincount) != 'integer' { fail("${autopurge_snapretaincount} is not an integer.") }
  if type($autopurge_purgeinterval) != 'integer' { fail("${autopurge_purgeinterval} is not an integer.") }
  if type($myid) != 'integer' { fail("${myid} is not an integer.") }

  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Packages
  # openjdk mandatory for zookeeper. gcj is bullhsit
  package { $packages:
    ensure => $openiosds::package_ensure,
    allow_virtual => false,
  } ->
  # Service
  openiosds::service {"${ns}-${type}-${num}":
    action => $action,
    type   => $type,
    num    => $num,
    ns     => $ns,
  } ->
  # Data path
  file { "${openiosds::sharedstatedir}/${ns}/${type}-${num}/data":
    ensure => $openiosds::directory_ensure,
    owner  => $openiosds::user,
    group  => $openiosds::group,
    mode   => $openiosds::directory_mode,
    require => Openiosds::Service["${ns}-${type}-${num}"]
  } ->
  # Configuration files
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/zoo.cfg":
    ensure => $openiosds::file_ensure,
    owner => $openiosds::user,
    group => $openiosds::group,
    content => template("openiosds/zoo.cfg.erb"),
    require => Package['zookeeper'],
  } ~>
  gridinit::program { "${ns}-${type}-${num}":
    action => $action,
    command => "java -Dzookeeper.log.dir=${openiosds::logdir}/${ns}/${type}-${num} -Dzookeeper.root.logger=INFO,ROLLINGFILE -cp ${openiosds::sysconfdir}/${ns}/${type}-${num}:${classpath} -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false org.apache.zookeeper.server.quorum.QuorumPeerMain ${openiosds::sysconfdir}/${ns}/${type}-${num}/zoo.cfg",
    group => "${ns},${type},${type}-${num}",
    uid => $openiosds::user,
    gid => $openiosds::group,
    no_exec => $no_exec,
  }
  # ZooKeeper Bootstrap
  if $bootstrap {
    exec { 'bootstrap':
      command => "/bin/sleep 10 && ${openiosds::bindir}/zk-bootstrap.py $ns",
      onlyif  => "/usr/bin/test -r ${openiosds::sysconfdir_globald}/${ns}",
      unless  => "/bin/sleep 3 && echo \"ls /hc/ns/$ns\" | ${openiosds::bindir}/zkCli.sh -server ${ipaddress}:${port} | grep srv" ,
      require => [Gridinit::Program["${ns}-${type}-${num}"],Openiosds::Namespace["$ns"]],
    }
  }
  if $myid {
    file {"${openiosds::sharedstatedir}/${ns}/${type}-${num}/data/myid":
      ensure => $openiosds::file_ensure,
      owner => $openiosds::user,
      group => $openiosds::group,
      content => $myid,
    }
  }

}
