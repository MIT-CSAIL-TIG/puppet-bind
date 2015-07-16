define bind::zone::generic ($zone = $name, $view, $order, $content,
			    $zone_type, $zone_file,
			    $notify_ = undef, $also_notify = undef,
			    $allow_transfer = undef) {
  include bind::config
  $view_config = "${bind::config::directory}/${view}.conf"

  if $content {
    concat::fragment {"${view_config}/${zone}":
      target  => $view_config,
      order   => $order,
      content => $content,
    }
  } else {
    fail("no content provided for $zone and nothing else is implemented")
  }
}
