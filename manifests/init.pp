#
# Main class to install and manage ISC BIND.  Written for and tested on
# BIND 9.10, but other versions may also work.
#
# If we're not going to be installing the BIND server, but just the tools,
# then don't try to do anything else.  This is because on some systems
# (e.g., FreeBSD), the bind-server package includes the tools and conflicts
# with the bind-tools package.  If installing the server, make sure that
# bind::tools knows so it doesn't try to install a package that conflicts
# with the server package.
#
# A site that wants to have bind-tools installed everywhere can simply set
# bind::tools_only to true in Hiera data, then override this setting in
# the machine classes that will actually run servers.
#
class bind ($tools_only, $ensure = 'present') {
  if ($tools_only) {
    anchor { 'bind::begin':
    } -> class { 'bind::tools':
      ensure            => $ensure,
      installing_server => false,
    } -> anchor { 'bind::end':
    }
  } else {
    anchor { 'bind::begin':
    } -> class { 'bind::package':
      ensure => $ensure,
    } -> class { 'bind::tools':
      ensure            => $ensure,
      installing_server => true,
    } -> class { 'bind::config':
      ensure => $ensure,
    } -> class { 'bind::service':
      ensure => $ensure,
    } -> anchor { 'bind::end':
    }
  }
}
