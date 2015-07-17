define bind::zone::generic ($zone = $name, $view, $order, $content,
			    $zone_type, $zone_file,
			    $notify_ = undef, $also_notify = undef,
			    $allow_transfer = undef) {
  include bind::config
  $view_config = "${bind::config::directory}/${view}.conf"

  validate_string($view)
  validate_string($order)
  validate_string($zone_type)
  validate_absolute_path($zone_file)
  if $notify_ != undef {
    validate_bool($notify_)
  }
  if $also_notify != undef {
    validate_array($also_notify)
  }
  if $allow_transfer != undef {
    validate_array($allow_transfer)
  }

  if is_string($content) {
    concat::fragment {"${view_config}/${zone}":
      target  => $view_config,
      order   => $order,
      content => template('bind/generic.conf.erb'),
    }
  } else {
    fail("no content provided for $zone and nothing else is implemented")
  }
}
