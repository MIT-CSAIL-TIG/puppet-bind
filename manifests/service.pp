#
# This module is responsible for controlling the BIND server.
# It assumes that rndc(8) has been configured so that "reconfig"
# commands can be sent through that channel rather than restarting
# the server using init scripts or the like.
#
class bind::service ($ensure) {
  # Actually, do nothing right now.
}

