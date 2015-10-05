#
# Instantiate a single zone as a master, in a specific view, using the
# indicated souce file, optionally with inline DNSSec signing.
#
define bind::zone::master ($zone = $name, $view, $source,
			   $inline_signing = false,
			   $allow_transfer = undef, $notify_ = undef,
			   $also_notify = undef,
			   ) {
  include bind::config
  $key_directory = $bind::config::keys_path
  $master_directory = $bind::config::master_path

  if $source =~ /^\// {
    $source_path = $source
  } else {
    $source_path = "${master_directory}/${source}"
  }

  bind::zone::generic {"${view}/${zone}":
    zone           => $zone,
    view           => $view,
    zone_type      => master,
    zone_file      => $source_path,
    allow_transfer => $allow_transfer,
    notify_        => $notify_,
    also_notify    => $also_notify,
    order          => "55",
    content        => template('bind/master.conf.erb'),
  }
}
