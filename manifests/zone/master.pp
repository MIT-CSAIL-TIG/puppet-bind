define bind::zone::master ($zone = $name, $view) {
  bind::zone::generic {$zone:
    order   => "55",
    content => template('bind/master.conf.erb'),
  }
}
