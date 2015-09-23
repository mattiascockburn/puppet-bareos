# == Define: bareos::director::fileset
#
# Configure an additional basic file set to be used by the Bacula clients. See the {FileSet
# Resource}[http://www.bareos.org/5.0.x-manuals/en/main/main/Configuring_Director.html#SECTION001870000000000000000] documentation
# for information on the options.
#
# === Parameters
#
# [*ensure*]
#   Ensure the file is present or absent.  The only valid values are <tt>file</tt> or
#   <tt>absent+. Defaults to <tt>file</tt>.
# [*exclude_files*]
#   An array of strings consisting of one file or directory name per entry. Directory names should be specified without
#   a trailing slash with Unix path notation.
# [*include_files*]
#   *Required*: An array of strings consisting of one file or directory name per entry. Directory names should be specified without
#   a trailing slash with Unix path notation.
#
# === Examples
#
#   $servicename_include_files = [
#     '/etc/servicename',
#     '/var/lib/servicename',
#     '/var/log/servicename',
#     '/var/spool/servicename',
#   ]
#   $servicename_exclude_files = [
#     '/var/lib/servicename/tmp'
#   ]
#
#   bareos::director::fileset { 'servicename' :
#     ensure         => file,
#     include_files => $servicename_include_files,
#     exclude_files => $servicename_exclude_files,
#   }
#
define bareos::director::fileset (
  $ensure   = 'file',
  $exclude_files = undef,
  $include_files = undef
) {

  if !($ensure in ['file', 'absent']) {
    fail('The only valid values for the ensure parameter are file or absent')
  }

  file { "/etc/bareos/bareos-dir.d/fileset-${name}.conf":
    ensure  => file,
    owner   => 'bareos',
    group   => 'bareos',
    mode    => '0640',
    content => template('bareos/fileset.conf.erb'),
    require => File['/etc/bareos/bareos-dir.conf'],
    before  => Service['bareos-dir'],
    notify  => Exec['bareos-dir reload'],
  }
}
