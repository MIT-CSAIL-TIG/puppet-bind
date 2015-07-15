define bind::zone::master ($zone = $name, $view, $source, $inline_signing
			   $allow_transfer = [], $notify, $also_notify,
			   ) {
  include bind::config
  $key_directory = $bind::config::key_directory

  bind::zone::generic {$zone:
    order   => "55",
    content => template('bind/master.conf.erb'),
  }
}
