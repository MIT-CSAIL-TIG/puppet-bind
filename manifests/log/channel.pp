define bind::log::channel ($channel = $name, $severity,
			   $facility = undef, $file = undef,
			   $print_category, $print_severity,
			   $print_time) {
  include bind::config
  $main_config = $bind::config::main_config

  if !($facility or $file) {
    fail("bind::log::channel: ${channel}: either facility or file must be specified")
  }

  concat::fragment {"${main_config}/logging-channel-${name}":
    target  => $main_config,
    order   => '10',
    content => template('bind/log-channel.conf.erb'),
  }
}
