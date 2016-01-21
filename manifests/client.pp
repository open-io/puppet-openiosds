# Install OpenIO SDS client
class openiosds::client () {

  package { 'python-oiopy':
    ensure        => $openiosds::package_ensure,
    allow_virtual => false,
  }

}
