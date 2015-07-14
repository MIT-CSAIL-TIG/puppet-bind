define bind::zone::other ($zone = $name, $configuration, $view) {
  bind::zone::generic {$zone:
    order   => "65",
    content => $configuration,
  }
}
