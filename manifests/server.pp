#
# This type is for generating "server" directives in the BIND
# configuration file.  For the setup of the actual BIND daemon,
# see service.pp in this directory.
#
define bind::server ($ensure = 'present', $extra = undef, $keys = [],
		     $address = $name) {
  validate_array($keys)

  if $extra == undef and size($keys) == 0 {
    fail('bind::server requires either keys or a config fragment')
  }
  
  include bind::config
  concat::fragment {"${bind::config::main_config}/server ${name}":
    target  => $bind::config::main_config,
    order   => '14',
    content => template('bind/server.conf.erb'),
  }
}

