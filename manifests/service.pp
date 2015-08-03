#
# This module is responsible for controlling the BIND server.
# It assumes that rndc(8) has been configured so that "reconfig"
# commands can be sent through that channel rather than restarting
# the server using init scripts or the like.
#
class bind::service ($ensure, $service_name) {
  include bind::config

  case $ensure {
    'present', 'latest': {
      $svc_ensure = 'running'
      $svc_enable = true
    }
    default: {
      $svc_ensure = 'stopped'
      $svc_enable = false
    }
  }

  service { 'named':
    name    => $service_name,
    ensure  => $svc_ensure,
    enable  => $svc_enable,
    restart => "${bind::config::rndc_command} reconfig",
  }
}
