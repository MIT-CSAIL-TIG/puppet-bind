#
# Install the BIND tools, which may or may not be in a separate
# package from BIND itself.  One challenge: if there are two packages,
# they may conflict!  So we have to gate everything through the
# main 'bind' class, which knows whether the server will be installed
# or not, and which will instantiate this class if and only if required.
# For now, all this does is ensure the package, but it's broken out this
# way in case there is ever some special configuration that needs to be
# done.
#
class bind::tools ($ensure,
    $packages,
    $installing_server,
    $tools_conflict_with_server
) {
  if ($ensure == 'present' or $ensure == 'latest') {
    if ($tools_conflict_with_server and $installing_server) {
      # do nothing
      anchor { 'bind::tools::empty': }
    } else {
      package { $packages: ensure => $ensure, }
    }
  } else {
    package { $packages: ensure => $ensure, }
  }
}
