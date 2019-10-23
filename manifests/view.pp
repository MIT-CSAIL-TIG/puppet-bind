#
# Instantiate a view.  This module does not (yet) support defining zones
# outside of views, so all of the important zone configuration is driven
# from here.  (You can define zones explicitly in Puppet DSL but they must
# reference a specific view name.)
#
define bind::view ($view = $name, $ensure = 'present',
		   $empty = hiera('bind::config::empty'),
		   $master_zones = {},
		   $slave_zones = {},
		   $other_zones = {},
		   $match_clients = undef,
		   $match_recursive_only = undef,
		   $minimal_responses = undef,
		   $recursion = undef,
		   $dnssec_validation = undef,
		   $allow_transfer = undef,
		   $notify_ = undef,
		   $also_notify = undef,
		   $zone_defaults = {},
		   $extra = undef,
		  ) {
  include bind::config
  $view_config = "${bind::config::directory}/${view}.conf"
  $main_config = $bind::config::main_config
  $root_hints  = $bind::config::root_hints

  concat { $view_config:
    ensure => $ensure,
    owner  => root,
    group  => '0',
    mode   => '0444',
    notify => Service['named'],
  }

  concat::fragment {"${view_config}/header":
    target  => $view_config,
    order   => '00',
    content => template('bind/view-header.conf.erb'),
  }

  concat::fragment {"${view_config}/disabled-empty-zones":
    target  => $view_config,
    order   => '44',
    content => "\n\t// These zones are covered by the explicitly defined empty zones below.\n",
  }
  # disable-empty-zone configuration lines are at order 45
  # forwarders are at order 46
  # real zones start here

  concat::fragment {"${view_config}/root-hints":
    target  => $view_config,
    order   => '49',
    content => template('bind/root-hints.conf.erb'),
  }

  $explicit_zones = union(union(keys($master_zones), keys($slave_zones)),
			  keys($other_zones))

  $my_zone_defaults = { view => $view }
  $all_zone_defaults = merge($zone_defaults, $my_zone_defaults)

  # real master zones are at order 55
  create_resources('bind::zone::master', $master_zones, $my_zone_defaults)

  # slave zones are at order 60
  create_resources('bind::zone::slave', $slave_zones, $my_zone_defaults)

  # weird miscellaneous zone types are at order 65
  create_resources('bind::zone::other', $other_zones, $my_zone_defaults)

  # empty zones are at order 90, because they make a lot of visual
  # clutter
  $emptyzones = delete($empty, $explicit_zones)
  bind::emptyzones {$view: ensure => $ensure, zones => $emptyzones, }

  concat::fragment {"${view_config}/trailer":
    target  => $view_config,
    order   => '99',
    content => template('bind/view-trailer.conf.erb'),
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
      content => "include \"${view_config}\";\n",
      require => Concat[$view_config],
    }
  }
}
