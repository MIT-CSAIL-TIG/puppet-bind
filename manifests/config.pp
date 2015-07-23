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
		    $tsig_keys, $remote_servers,
		    $pid_file = undef, # has compiled-in default
		    $dump_file = undef, # has compiled-in default
		    $statistics_file = undef, # has compiled-in default
		    $checkconf = undef, # skip validation if not defined
		    $named_conf,
		    $views) {

  # Validate data types first.  These are all on separate lines because
  # the error message only gives a line number, not the actual variable
  # that had the incorrect type of value, so that's is the only way to
  # identify where the problem is.
  validate_hash($log_channels)
  validate_hash($log_categories)
  validate_hash($tsig_keys)
  validate_hash($remote_servers)
  validate_hash($views)
  validate_absolute_path($directory)
  validate_bool($install_root_hints)
  validate_bool($log_queries_by_default)
  validate_string($root_hints)
  validate_string($master_dir)
  validate_string($slave_dir)
  validate_string($keys_dir)
  validate_string($working_dir)
  validate_string($named_conf)

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

  # include directives for the individual view configurations get inserted
  # here
  create_resources('bind::view', $views, {})

  #concat::fragment {"${main_config}/trailer":
  #  target  => $main_config,
  #  order   => '99',
  #  content => template('bind/main-trailer.conf.erb'),
  #}
}
