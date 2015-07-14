#
# This module is the most complicated of them all, and actually
# handles generating the configuration files for BIND in any of
# a few different formats.  Where feasible we try to reuse the
# package's configuration structure, which makes this more complex
# than it might otherwise be.
#
# The basic model is that every server has some set of views.
# Each view ends up in a configuration file; there is a special
# view called "default" which ends up in the main configuration
# file.  In addition, there are zones, each of which represents
# a zone which may be instantiated into one or more views, as
# well as special empty zones for handling queries which should
# always return NXDOMAIN.  There are ACLs, which are always included
# in the main configuration file, and may use either TSIG keys or
# IP addresses.  Finally, there are keys and log destinations,
# and how they work has yet to be defined.
#
class bind::config ($ensure, $directory, $root_hints, $install_root_hints) {

  # Normally assume that the BIND package will include an up-to-date
  # root hint file, and require explicit configuration to replace it
  # with a different version.  You might want to do this if for some
  # reason you are stuck with an outdated BIND package (in which case
  # I hope you're not exposed to the Internet) that has bad hints
  # in it.  (And even then, under normal circumstances all you need is
  # just one of the 13 root servers to work!)
  if $install_root_hints {
    file {$root_hints:
      ensure => $ensure,
      owner  => root,
      group  => 0,
      mode   => '0444',
      source => 'puppet:///modules/bind/root.hints',
    }
  }
}
