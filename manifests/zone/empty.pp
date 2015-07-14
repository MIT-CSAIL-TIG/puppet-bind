#
# A kind of zone resource that is specialized for serving "empty"
# zones (e.g., the AS112 zones).  This might some day be unified with
# a bind::zone::master type.  It's written in such a way that it can
# be directly instantiated in a manifest, although I don't expect that
# anyone would ever want to do that (change your data in hiera
# instead).
#
define bind::zone::empty ($zone = $name, $view = 'default', $db) {
  include bind::config
  $view_config = "${bind::config::directory}/${view}.conf"

  # Not sure if this can be in a view or if it has to be at the top level
  # Would need a separate defined resource to implement that!
  concat::fragment {"disable-empty-zone $name in $view":
    target  => $view_config,
    order   => "45",
    content => "\tdisable-empty-zone \"${zone}\";\n",
  }

  bind::zone::generic {$zone:
    order   => "50",
    content => template("bind/empty-zone.conf.erb"),
  }
}
