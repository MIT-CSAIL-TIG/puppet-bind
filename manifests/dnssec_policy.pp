#
# Define a DNSsec signing and key rotation policy.
#
define bind::dnssec_policy (Optional[String] $dnskey_ttl, # actually a BIND-format time
			    Optional[String] $sig_refresh, # ditto
			    Optional[String] $sig_validity, # ditto
			    Optional[String] $dnskey_sig_validity, # ""
			    Optional[Hash] $ksk,
			    Optional[Hash] $zsk,
			    Optional[Hash] $csk,
			    String $policy = $name,
) {

  if defined($csk) {
    if defined($ksk) or defined($zsk) {
      fail("${name}: CSK and KSK/ZSK are mutually exclusive")
    }
  } elsif defined($ksk) {
    if !defined($zsk) {
      fail("${name}: ZSK required when KSK is present")
    }
  } elsif defined($zsk) {
    fail("${name}: KSK required when ZSK is present")
  } else {
    fail("${name}: either CSK or KSK+ZSK must be specified")
  }

  include bind::config
  $main_config = $bind::config::main_config

  concat::fragment {"${main_config}/dnssec-policy-${policy}":
    target  => $main_config,
    order   => '25',
    content => template('bind/dnssec-policy.conf.erb'),
  }
}
