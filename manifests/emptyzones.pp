define bind::emptyzones (zones, $view = $name, $ensure = 'present') {
  include bind::config
  require bind::zone::empty_db
  $empty_db = $bind::zone::empty_db::db

  # Maybe elide this extra defined type and just construct directly
  # from fragments here?
  $bind::emptyzones::zones.each |$zone| {
    bind::zone::empty { "${view}/${zone}":
      zone => $zone,
      view => $view,
      db   => $empty_db,
    }
  }
}
