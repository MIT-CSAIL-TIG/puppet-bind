# Defines a slave zone named ZONE in view VIEW.  If FILE is not
# specified, choose an appropriate (view-specific) file to store
# the transferred zone data in.
define bind::zone::slave ($zone = $name, $view, $file = undef,
			  $masters, $allow_transfer = undef,
			  $inline_signing = false, $notify_ = undef,
			  $also_notify = undef) {
  include bind::config
  $key_directory = $bind::config::keys_path
  if $file {
    $zone_file = $file
  } else {
    # N.B.: must be unique; BIND cannot share slave zone files between views.
    $zone_file = "${bind::config::slave_path}/${view}-${zone}.db"
  }
  bind::zone::generic {"${view}/${zone}":
    zone           => $zone,
    view           => $view,
    zone_type      => slave,
    zone_file      => $zone_file,
    allow_transfer => $allow_transfer,
    notify_        => $notify_,
    also_notify    => $also_notify,
    order          => "60",
    content        => template('bind/slave.conf.erb'),
  }
}
