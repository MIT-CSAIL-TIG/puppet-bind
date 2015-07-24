#
# Define an access-control list in named.conf.  The resource title
# should be the name of the ACL, and $keys and $addresses represent
# the entries in the ACL.
#
define bind::acl ($acl = $name, $keys = [], $addresses = []) {
  validate_array($keys)
  validate_array($addresses)

  if size($keys) + size($addresses) == 0 {
    fail("bind::acl: ${acl}: either keys or addresses must be provided")
  }

  include bind::config
  $main_config = $bind::config::main_config

  concat::fragment {"${main_config}/acl-${acl}":
    target  => $main_config,
    order   => '25',
    content => template('bind/acl.conf.erb'),
  }
}
