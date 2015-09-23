# == Class: bareos::client
#
# This class manages the bareos client (bareos-fd)
#
# === Parameters
#
# All <tt>bareos+ classes are called from the main <tt>::bareos</tt> class.  Parameters
# are documented there.
#
# === Actions:
# * Enforce the client package package be installed
# * Manage the <tt>/etc/bareos/bareos-fd.conf</tt> file
# * Enforce the <tt>bareos-fd</tt> service to be running
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
class bareos::client (
  $ensure            = $::bareos::params::client_ensure, 
  $client_packages   = $::bareos::params::client_packages,
  $service_name      = $::bareos::params::client_service_name,
  $confdir           = $::bareos::params::client_confdir,
  $client_config     = $::bareos::params::client_config_filename,
  $director_password = '',
  $director_server   = $::bareos::params::director_server_default,
  $plugin_dir        = undef,
  $tls_allowed_cn    = [],
  $tls_ca_cert       = undef,
  $tls_ca_cert_dir   = undef,
  $tls_cert          = undef,
  $tls_key           = undef,
  $tls_require       = 'yes',
  $tls_verify_peer   = 'yes',
  $use_tls           = false
) inherits ::bareos::params {

  #  $file_requires = $plugin_dir ? {
  #    undef   => File['/var/lib/bareos', '/var/run/bareos'],
  #    default => File['/var/lib/bareos', '/var/run/bareos', $plugin_dir]
  #  }

  $fd_conf = "${confdir}/${client_config}"
  validate_absolute_path($fd_conf)

  case $ensure {
    /(present|enabled)/: {
      $service_ensure = 'running'
      $service_enable = true
      $package_ensure = 'present'
      Package[$client_packages] -> File[$fd_conf] ~> Service[$service_name]
    }
    'disabled': {
      $service_ensure = 'stopped'
      $service_enable = false
      $package_ensure = 'present'
      Package[$client_packages] -> File[$fd_conf] ~> Service[$service_name]
    }
    'absent': {
      $service_ensure = 'stopped'
      $service_enable = false
      $package_ensure = 'absent'
      Service[$service_name] -> Package[$client_packages] -> File[$fd_conf]
    }
    default: {
      fail("ensure must be set to either present, enabled, disabled or absent. Not $ensure")
    }
  }

  package { $client_packages:
    ensure => $package_ensure,
  }

  file { $fd_conf:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('bareos/bareos-fd.conf.erb'),
  }

  service { $service_name:
    ensure     => $service_ensure,
    enable     => $service_enable,
  }


}
