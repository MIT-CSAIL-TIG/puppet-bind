class bind::tsig_keys ($ensure = 'present') {
  include bind::config

  $tsig_keys = "${bind::config::keys_path}/tsig.keys"
  concat { $tsig_keys:
    ensure => $ensure,
    owner  => root,
    group  => "0",
    mode   => "0444",
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
