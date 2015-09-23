# == Class: bareos::console
#
# This class manages the bconsole application
#
# === Parameters
#
# All <tt>bareos+ classes are called from the main <tt>::bareos</tt> class.  Parameters
# are documented there.
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
class bareos::console (
  $console_template  = 'bareos/bconsole.conf.erb',
  $director_password = '',
  $director_server   = undef,
  $tls_ca_cert       = undef,
  $tls_ca_cert_dir   = undef,
  $tls_cert          = undef,
  $tls_key           = undef,
  $tls_require       = 'yes',
  $tls_verify_peer   = 'yes',
  $use_tls           = false
) {
  include ::bareos::params

  $director_server_real = $director_server ? {
    undef   => $::bareos::params::director_server_default,
    default => $director_server,
  }

  package { $::bareos::params::console_package:
    ensure => present,
  }

  file { '/etc/bareos/bconsole.conf':
    ensure  => file,
    owner   => 'bareos',
    group   => 'bareos',
    mode    => '0640',
    content => template($console_template),
    require => Package[$::bareos::params::console_package],
  }
}
