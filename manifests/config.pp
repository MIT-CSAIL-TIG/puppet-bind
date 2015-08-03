#
# This module is the most complicated of them all, and actually
# handles generating the configuration files for BIND in any of
# a few different formats.  Where feasible we try to reuse the
# package's configuration structure, which makes this more complex
# than it might otherwise be.
#
# The basic model is that every server has some set of views.
# Each view ends up in a configuration file; the default view, if
# no other views are configured, will give a localhost-only caching
# server.  In addition, there are zones, which are instantiated into
# views, as well as special empty zones for handling queries which should
# always return NXDOMAIN.  There are ACLs, which are always included
# in the main configuration file, and may use either TSIG keys or
# IP addresses.  Finally, there are keys and log destinations,
# and how they work has yet to be defined.
#
class bind::config ($ensure, $directory, $root_hints, $install_root_hints,
		    $log_queries_by_default, $log_channels, $log_categories,
		    $master_dir, $slave_dir, $keys_dir, $working_dir,
		    $bind_user, $bind_group, $bind_owns_work_directories,
		    $tsig_keys, $remote_servers, $acls, $options,
		    $trusted_keys,
		    $pid_file = undef, # has compiled-in default
		    $dump_file = undef, # has compiled-in default
		    $statistics_file = undef, # has compiled-in default
		    $checkconf = undef, # skip validation if not defined
		    $extra = undef, # don't need any extras
		    $named_conf, $rndc_command,
		    $views) {

  # Validate data types first.  These are all on separate lines because
  # the error message only gives a line number, not the actual variable
  # that had the incorrect type of value, so that's is the only way to
  # identify where the problem is.
  validate_hash($acls)
  validate_hash($log_channels)
  validate_hash($log_categories)
  validate_hash($options)
  validate_hash($trusted_keys)
  validate_hash($remote_servers)
  validate_hash($tsig_keys)
  validate_hash($views)
  validate_absolute_path($directory)
  if $pid_file != undef {
    validate_absolute_path($pid_file)
  }
  if $checkconf != undef {
    validate_absolute_path($checkconf)
  }
  if $dump_file != undef {
    validate_string($dump_file) # may be relative to $working_dir
  }
  if $statistics_file != undef {
    validate_string($statistics_file) # ditto
  }
  validate_bool($install_root_hints)
  validate_bool($log_queries_by_default)
  validate_bool($bind_owns_work_directories)
  validate_string($root_hints)
  validate_string($master_dir)
  validate_string($slave_dir)
  validate_string($keys_dir)
  validate_string($working_dir)
  validate_string($bind_user)
  validate_string($bind_group)
  validate_string($named_conf)
  validate_string($rndc_command)
  if $extra != undef {
    validate_string($extra)
  }

  # named will resolve these automatically relative to its working directory.
  # We want them relative to the configuration directory, and we potentially
  # want to be able to reference them in Puppet file resources, which need
  # an absolute path.

  # Assume for now that these will never be absolute.
  $master_path = "${directory}/${master_dir}"
  $slave_path  = "${directory}/${slave_dir}"
  $keys_path   = "${directory}/${keys_dir}"
  $main_config = "${directory}/${named_conf}"

  # This often will be absolute, since Linux systems like to hide
  # the working directory off in /var somewhere.
  if $working_dir =~ /^\// {
    $working_path = $working_dir
  } else {
    $working_path = "${directory}/working"
  }

  # Make sure that the relevant directories all exist (they might not
  # be created by the package in some cases).
  case $ensure {
    'present', 'latest': { $dir_ensure = 'directory' }
    default: { $dir_ensure = 'absent' }
  }
  file { [$master_path, $keys_path]:
    ensure => $dir_ensure,
    owner  => root,
    group  => '0',
    mode   => '0755',
  }
  file { [$working_path, $slave_path]:
    ensure => $dir_ensure,
    group  => $bind_group,
    purge  => $ensure == 'purged',
    force  => $ensure == 'purged',
  }
  if $bind_owns_work_directories {
    File[$slave_path] { owner => $bind_user, mode  => '0755', }
    File[$working_path] { owner => $bind_user, mode  => '0755', }
  } else {
    File[$slave_path] { owner => root, mode  => '0775', }
    File[$working_path] { owner => root, mode  => '0775', }
  }

  # Normally assume that the BIND package will include an up-to-date
  # root hint file, and require explicit configuration to replace it
  # with a different version.  You might want to do this if for some
  # reason you are stuck with an outdated BIND package (in which case
  # I hope you're not exposed to the Internet) that has bad hints
  # in it.  (And even then, under normal circumstances all you need is
  # just one of the 13 root servers to work!)
  if $install_root_hints {
    file {$root_hints:
      ensure => $ensure,
      owner  => root,
      group  => '0',
      mode   => '0444',
      source => 'puppet:///modules/bind/root.hints',
    }
  }

  concat { $main_config:
    ensure => $ensure,
    owner  => root,
    group  => '0',
    mode   => '0444',
    notify => Service['named'],
  }
  if $checkconf {
    Concat[$main_config] { validate_cmd => "${checkconf} %", }
  }

  concat::fragment {"${main_config}/header":
    target  => $main_config,
    order   => '00',
    content => template('bind/main-header.conf.erb'),
  }

  $channel_defaults = {
    print_category => true,
    print_severity => false,
    print_time     => false,
  }
  $category_defaults = {
    channels => ['main'],
  }

  concat::fragment {"${main_config}/logging-start":
    target  => $main_config,
    order   => '08',
    content => "logging {\n",
  }

  create_resources('bind::log::channel', $log_channels, $channel_defaults)
  create_resources('bind::log::category', $log_categories, $category_defaults)

  concat::fragment {"${main_config}/logging-end":
    target  => $main_config,
    order   => '12',
    content => "};\n",
  }

  # Define keys and servers for transaction signature (TSIG) security
  create_resources('bind::tsig', $tsig_keys, {})
  create_resources('bind::server', $remote_servers, {})

  # Any literal configuration goes here.  We use this for things like
  # response-rate limiting, which many sites won't need and has too many
  # individual configuration options to represent directly in the parameters
  # to this class.
  if $extra != undef {
    concat::fragment {"${main_config}/extra":
      target  => $main_config,
      order   => '20',
      content => $extra,
    }
  }

  # Automatically instantiate some default ACLs for convenience
  $management_stations = hiera_array('management_stations', [])
  if size($management_stations) > 0 {
    bind::acl {'management_stations': addresses => $management_stations, }
  }
  $local_netblocks = hiera_array('local_netblocks', [])
  $local_netblocks_v6 = hiera_array('local_netblocks_v6', [])
  if size($local_netblocks) + size($local_netblocks_v6) > 0 {
    bind::acl {'local_netblocks':
      addresses => union($local_netblocks, $local_netblocks_v6),
    }
  }
  $campus_netblocks = hiera_array('campus_netblocks', [])
  $campus_netblocks_v6 = hiera_array('campus_netblocks_v6', [])
  if size($campus_netblocks) + size($campus_netblocks_v6) > 0 {
    bind::acl {'campus_netblocks':
      addresses => union($campus_netblocks, $campus_netblocks_v6),
    }
  }

  create_resources('bind::acl', $acls, {})

  create_resources('bind::trust_anchor', $trusted_keys, {})

  # include directives for the individual view configurations get inserted
  # here
  create_resources('bind::view', $views, {})

  #concat::fragment {"${main_config}/trailer":
  #  target  => $main_config,
  #  order   => '99',
  #  content => template('bind/main-trailer.conf.erb'),
  #}
}
