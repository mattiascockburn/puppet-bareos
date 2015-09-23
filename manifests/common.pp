# == Class: bareos::common
#
# This class enforces common resources needed by all bareos components
#
# === Parameters
#
# All <tt>bareos+ classes are called from the main <tt>::bareos</tt> class.  Parameters
# are documented there.
#
# === Actions:
# * Enforce the bareos user and groups exist
# * Enforce the <tt>/var/spool/bareos+ is a director and <tt>/var/lib/bareos</tt>
#   points to it
#
# === Copyright
#
# Copyright 2012 Russell Harrison
#
# === License
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
class bareos::common (
  $db_backend        = 'sqlite',
  $db_database       = 'bareos',
  $db_host           = 'localhost',
  $db_password       = '',
  $db_port           = '3306',
  $db_user           = '',
  $is_client         = true,
  $is_director       = false,
  $is_storage        = false,
  $manage_bat        = false,
  $manage_console    = false,
  $manage_config_dir = false,
  $manage_db_tables  = true,
  $packages          = undef,
  $plugin_dir        = undef
) {
  include ::bareos::params

  if $packages {
    $packages_notify = $manage_db_tables ? {
      true    => Exec['make_db_tables'],
      default => undef,
    }

    package { $packages:
      ensure => installed,
      notify => $packages_notify,
    }
  }

  # The user and group are actually created by installing the bareos-common
  # package which is pulled in when any other bareos package is installed.
  # To work around the issue where every package resource is a separate run of
  # yum we add requires for the packages we already have to the group resource.
  if $is_client {
    $require_package = $::bareos::params::client_packages
  } elsif $is_director {
    $require_package = $::bareos::director::db_package
  } elsif $is_storage {
    $require_package = $::bareos::storage::db_package
  } elsif $manage_console {
    $require_package = $::bareos::params::console_package
  } elsif $manage_bat {
    $require_package = $::bareos::params::bat_console_package
  }

  if $plugin_dir {
    file { $plugin_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
  }

  # Specify the user and group are present before we create files.
  group { 'bareos':
    ensure  => present,
    require => Package[$require_package],
  }

  user { 'bareos':
    ensure  => present,
    gid     => 'bareos',
    require => Group['bareos'],
  }

  $config_dir_source = $manage_config_dir ? {
    true    => 'puppet:///modules/bareos/bareos-empty.dir',
    default => undef,
  }

  file { '/etc/bareos':
    ensure  => directory,
    owner   => 'bareos',
    group   => 'bareos',
    mode    => '0750',
    purge   => $manage_config_dir,
    force   => $manage_config_dir,
    recurse => $manage_config_dir,
    source  => $config_dir_source,
    require => Package[$require_package],
  }

  # This is necessary to prevent the object above from deleting the supplied scripts
  file { '/etc/bareos/scripts':
    ensure  => directory,
    owner   => 'bareos',
    group   => 'bareos',
    require => Package[$require_package],
  }

  file { '/var/lib/bareos':
    ensure  => directory,
    owner   => 'bareos',
    group   => 'bareos',
    mode    => '0755',
    require => Package[$require_package],
  }

  file { '/var/spool/bareos':
    ensure  => directory,
    owner   => 'bareos',
    group   => 'bareos',
    mode    => '0755',
    require => Package[$require_package],
  }

  file { '/var/log/bareos':
    ensure  => directory,
    recurse => true,
    owner   => 'bareos',
    group   => 'bareos',
    mode    => '0755',
    require => Package[$require_package],
  }

  file { '/var/run/bareos':
    ensure  => directory,
    owner   => 'bareos',
    group   => 'bareos',
    mode    => '0755',
    require => Package[$require_package],
  }
}
