#
# Instantiate the concat resource for the keys_dir/tsig.keys file and
# arranges for named.conf to include the generated file.  In a separate
# class so that it will only be generated/included if there are
# bind::tsig resources that require it.
#
class bind::tsig_keys ($ensure = 'present') {
  include bind::config

  $tsig_keys = "${bind::config::keys_path}/tsig.keys"
  concat { $tsig_keys:
    ensure => $ensure,
    owner  => root,
    group  => '0',
    mode   => '0444',
    warn   => true,
  }
  if $bind::config::checkconf {
    Concat[$tsig_keys] { validate_cmd => "${bind::config::checkconf} %", }
  }

  concat::fragment { "${bind::config::main_config}/include ${tsig_keys}":
    target  => $bind::config::main_config,
    order   => '13',
    content => "include \"${tsig_keys}\";\n",
  }
}
