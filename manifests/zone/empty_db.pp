class bind::zone::empty_db ($ensure = 'present') {
  include bind::config
  $db = "${bind::config::master_path}/empty.db"
  file {$db:
    ensure => $ensure,
    owner  => root,
    group  => '0',
    source => 'puppet:///modules/bind/empty.db',
    mode   => '0444',
  }
}
