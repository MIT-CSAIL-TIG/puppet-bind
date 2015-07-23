#
# Configure TSIG keys.
#
# There are three ways we might implement this:
# 1) Generate random keys on "client" machines (typically slaves)
#    and use exported resources to ship them to the master.  Requires
#    writing Ruby code to parse BIND keyfiles (which are not in the
#    format that BIND actually accepts for configuring TSIG keys)
#    and turn them into facts that can be used to generate the resources.
#    Potentially painful.
#
# 2) Generate random keys on "server" machines (typically masters)
#    and use exported resorces to ship them to the clients.  Same
#    drawbacks as the above; which one makes more sense depends a
#    lot on how you think about your security model.
#
# 3) Make the administrator do all the work of generating keys, and
#    just stick them directly into Puppet (probably as Hiera data,
#    although it should work in a manifest).  If we get this right,
#    implementing the other two should be a Small Matter of Programming.
#
# I've been going back and forth on this, in terms of how it ought to
# work, and decided to go the simplest (and most secure, in our
# environment) route, which is #3.  The security issue for us is that
# users can control what role puppet thinks their machines have, which
# would allow them to affect how the master is configured.
#
# The "name" of the resource MUST be the actual "name" of the key to be
# configured.
#
define bind::tsig ($ensure = 'present', $secret, $algorithm) {
  validate_string($secret, $algorithm)

  include bind::config
  $keys_path = $bind::config::keys_path
  $tsig_keys = "${keys_path}/tsig.keys"

  require bind::tsig_keys
  concat::fragment { "${tsig_keys}/${name}":
    target  => "${tsig_keys}",
    order   => '10',
    content => template('bind/tsig_key.conf.erb'),
  }
}
