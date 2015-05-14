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
class bind::config ($ensure) {
  # Actually do nothing yet.
}
