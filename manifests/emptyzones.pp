define bind::emptyzones ($view = $name, $ensure = 'present', $zones) {
  include bind::config
  require bind::zone::empty_db
  $empty_db = $bind::zone::empty_db::db

  # Maybe elide this extra defined type and just construct directly
  # from fragments here?
  $zones.each |$zone| { 
    bind::zone::empty { $zone: view => $view, db => $empty_db, }
  }
}
