# Define bareos::director::fileset
#
# Used to create filesets resources
#
define bareos::director::fileset (
  $ensure                 = 'file',
  $signature              = 'MD5',
  $compression            = 'GZIP',
  $onefs                  = '',
  $fstype                 = '',
  $recurse                = '',
  $sparse                 = '',
  $noatime                = '',
  $mtimeonly              = '',
  $keepatime              = '',
  $checkfilechanges       = '',
  $hardlinks              = '',
  $ignorecase             = '',
  $include                = '',
  $exclude                = '',
  $ignore_fileset_changes = '',
  $options_hash           = {},
  $restart                = true,
  $template               = 'bareos/director/fileset.conf.erb'
) {

  include ::bareos::params

  $array_filesets_fstype = is_array($fstype) ? {
    false     => $fstype ? {
      ''      => [],
      default => [$fstype],
    },
    default   => $fstype,
  }

  $array_filesets_include = is_array($include) ? {
    false     => $include ? {
      ''      => [],
      default => [$include],
    },
    default   => $include,
  }

  $array_filesets_exclude = is_array($exclude) ? {
    false     => $exclude ? {
      ''      => [],
      default => [$exclude],
    },
    default   => $exclude,
  }

  $manage_fileset_file_content = $template ? {
    ''      => undef,
    default => template($template),
  }

  $fileset_conf = "${bareos::params::director_confd}/fileset-${name}.conf"

  file { $fileset_conf:
    ensure  => $ensure,
    mode    => $::bareos::params::config_file_mode,
    owner   => $::bareos::params::config_owner,
    group   => $::bareos::params::config_group,
    require => Package[$::bareos::params::director_packages],
    content => $manage_fileset_file_content,
  }

  if $restart {
    File[$fileset_conf] ~> Service[$bareos::params::director_service]
  }

}

