define bind::log::category ($category = $name, $channels) {
  include bind::config
  $main_config = $bind::config::main_config

  concat::fragment {"${main_config}/logging-category-${name}":
    target  => $main_config,
    order   => '11',
    content => template('bind/log-category.conf.erb'),
  }
}
