define bind::view ($view = $name, $ensure = 'present',
		   $empty = hiera('bind::config::empty'),
		   $master_zones = {},
		   $slave_zones = {},
		   $other_zones = {},
		   $match_clients = undef,
		   $match_recursive_only = undef,
		   $minimal_responses = undef,
		   $recursion = undef,
		   $additional_from_cache = undef,
		   $dnssec_validation = undef,
		   $dnssec_lookaside = undef,
		   $allow_transfer = undef,
		   $notify = undef,
		   $also_notify = undef,
		   $zone_defaults = {},
		  ) {
  include bind::config
  $view_config = "${bind::config::directory}/${view}.conf"
  $main_config = "${bind::config::directory}/named.conf"
  $root_hints  = $bind::config::root_hints

  concat { $view_config:
    ensure => $ensure,
    owner  => root,
    group  => 0,
    mode   => '0444',
  }

  concat::fragment {"${view_config}/header":
    target => $view_config,
    order  => '00',
    source => 'puppet:///modules/bind/view-header.conf.erb',
  }

  concat::fragment {"${view_config}/disabled-empty-zones":
    target  => $view_config,
    order   => '44',
    content => "\n// These zones are covered by the explicitly defined empty zones below.\n",
  }
  # disable-empty-zone configuration lines are at order 45
  # forwarders are at order 46
  # real zones start here

  concat::fragment {"${view_config}/root-hints":
    target  => $view_config,
    order   => 49,
    content => template('bind/root-hint.conf.erb'),
  }
  
  # empty zones are at order 50
  bind::emptyzones {$view: ensure => $ensure, zones => $emptyzones, }

  $my_zone_defaults = { view => $view }
  $all_zone_defaults = merge($zone_defaults, $my_zone_defaults)

  # real master zones are at order 55
  define_resources('bind::zone::master', $master_zones, $my_zone_defaults)

  # slave zones are at order 60
  define_resources('bind::zone::slave', $slave_zones, $my_zone_defaults)

  # weird miscellaneous zone types are at order 65
  define_resources('bind::zone::other', $other_zones, $my_zone_defaults)

  concat::fragment {"${view_config}/trailer":
    target => $view_config,
    order  => '99',
    source => 'puppet:///modules/bind/view-trailer.conf.erb',
  }

  # If ensure is anything other than "present", treat it as "absent".
  # This allows the configuration for a view to be removed automatically.
  # (Note that this is different from removing the view from the manifest:
  # in that case, the view will no longer be configured but the configuration
  # file itself will not be deleted.)
  if $ensure == 'present' {
    concat::fragment {"${main_config}/${view_config}":
      target  => $main_config,
      order   => '50',
      content => "include \"${view}.conf\";\n",
    }
  }
}
