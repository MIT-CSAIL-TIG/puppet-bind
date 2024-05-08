#
# Install the BIND server package(s) and, if desired, documentation.
#
class bind::package ($ensure,
    $packages,
    $install_documentation,
    $version,
    $documentation_packages = []
) {
  package { $packages:
    ensure => $ensure,
  }
  if ($install_documentation and !empty($documentation_packages)) {
    package { $documentation_packages:
      ensure => $ensure,
    }
  }
}
