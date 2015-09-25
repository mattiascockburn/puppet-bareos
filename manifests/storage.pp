# == Class: bareos::storage
#
# This class manages the bareos storage daemon (bareos-sd)
#
# === Parameters
#
# All <tt>bareos+ classes are called from the main <tt>::bareos</tt> class.  Parameters
# are documented there.
#
# === Actions:
# * Enforce the DB component package package be installed
# * Manage the <tt>/etc/bareos/bareos-sd.conf</tt> file
# * Manage the <tt>${storage_default_mount}+ and <tt>${storage_default_mount}/default</tt> directories
# * Manage the <tt>/etc/bareos/bareos-sd.conf</tt> file
# * Enforce the <tt>bareos-sd</tt> service to be running
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
class bareos::storage (
  $console_password      = '',
  $db_backend            = 'sqlite',
  $director_password     = '',
  $director_server       = undef,
  $plugin_dir            = undef,
  $storage_default_mount = '/mnt/bareos',
  $storage_server        = undef,
  $storage_template      = 'bareos/bareos-sd.conf.erb',
  $tls_allowed_cn        = [],
  $tls_ca_cert           = undef,
  $tls_ca_cert_dir       = undef,
  $tls_cert              = undef,
  $tls_key               = undef,
  $tls_require           = 'yes',
  $tls_verify_peer       = 'yes',
  $use_tls               = false
) {
  include ::bareos::params

  $director_server_real = $director_server ? {
    undef   => $::bareos::params::director_server_default,
    default => $director_server,
  }
  $storage_server_real  = $storage_server ? {
    undef   => $::bareos::params::storage_server_default,
    default => $storage_server,
  }

  # This is necessary because the bareos-common package will
  # install the bareos-storage-mysql package regardless of
  # wheter we're installing the bareos-storage-sqlite package
  # This causes the bareos storage daemon to use mysql no
  # matter what db backend we want to use.
  #
  # However, if we install only the db compoenent package,
  # it will install the bareos-common package without
  # necessarily installing the bareos-storage-mysql package
  $db_package           = $db_backend ? {
    'mysql'      => $::bareos::params::database_package_mysql,
    'postgresql' => $::bareos::params::database_package_pgsql,
    'sqlite'      => $::bareos::params::database_package_sqlite,
  }

  ensure_packages($db_package)

  package { $::bareos::params::storage_package:
    ensure => present,
  }

  file { "${storage_default_mount}/default":
    ensure  => directory,
    owner   => 'bareos',
    group   => 'bareos',
    mode    => '0755',
    require => Package[$db_package], 
  }

  file { '/etc/bareos/bareos-sd.d':
    ensure  => directory,
    owner   => 'bareos',
    group   => 'bareos',
    mode    => '0750',
    require => Package[$db_package],
  }

  file { '/etc/bareos/bareos-sd.d/empty.conf':
    ensure => file,
    owner  => 'bareos',
    group  => 'bareos',
    mode   => '0640',
  }

  $file_requires = $plugin_dir ? {
    undef   => File[
      '/etc/bareos/bareos-sd.d/empty.conf',
      "${storage_default_mount}/default",
      '/var/lib/bareos',
      '/var/run/bareos'
    ],
    default => File[
      '/etc/bareos/bareos-sd.d/empty.conf',
      "${storage_default_mount}/default",
      '/var/lib/bareos',
      '/var/run/bareos',
      $plugin_dir
    ],
  }

  file { '/etc/bareos/bareos-sd.conf':
    ensure  => file,
    owner   => 'bareos',
    group   => 'bareos',
    mode    => '0640',
    content => template($storage_template),
    require => $file_requires,
    notify  => Service['bareos-sd'],
  }

  # Register the Service so we can manage it through Puppet
  service { 'bareos-sd':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}
