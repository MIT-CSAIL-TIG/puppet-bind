#
# Define a trust anchor (that is, a public key that is explicitly
# trusted for DNSsec signatures of a particular domain).  You should
# not use this for the root domain; allow BIND to do automatic
# key management for the root.
#
define bind::trust_anchor ($domain = $name, $keys) {
  validate_array($keys)

  include bind::config

  $main_config = $bind::config::main_config
  $version = $bind::package::version
  $trusted_keys_is_deprecated = (versioncmp($version, '9.15') >= 0)

  if $trusted_keys_is_deprecated {
    ensure_resource('concat::fragment', "${main_config}/anchor-begin",
      { target => $main_config, order => '29', content => "dnssec-keys {\n", })
  } else {
    ensure_resource('concat::fragment', "${main_config}/anchor-begin",
      { target => $main_config, order => '29', content => "trusted-keys {\n", })
  }
  ensure_resource('concat::fragment', "${main_config}/anchor-end",
    { target => $main_config, order => '31', content => "};\n", })

  concat::fragment { "${main_config}/anchor-${domain}":
    target  => $main_config,
    order   => '30',
    content => template('bind/trust_anchor.conf.erb'),
  }
}
