define bind::zone::slave ($zone = $name, $view) {
  bind::zone::generic {$zone:
    order   => "60",
    content => template('bind/slave.conf.erb'),
  }
}
