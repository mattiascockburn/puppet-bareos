# == Class: bareos::params
#
# Default values for parameters needed to configure the <tt>bareos</tt> class.
#
# === Parameters
#
# None
#
# === Examples
#
#  include ::bareos::params
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
class bareos::params {
  case $::operatingsystem {
    'SLES': { }
    default: { fail("Class[bareos]: Not supported on OS ${::operatingsystem}") }
  }
  # defaults for trigger parameters
  $manage_packages = true
  $manage_database = true
  $manage_logwatch = true

  $bat_console_package          = 'bareos-bat'
  $console_package              = 'bareos-bconsole'

  # Director Defaults
  $director_packages             = ['bareos-director']
  $director_additional_packages = ['bareos-director-python-plugin']
  $director_server_default      = "bareos.${::domain}"
  $director_service             = 'bareos-dir'
  $lib    = $::architecture ? {
    x86_64  => 'lib64',
    default => 'lib',
  }
  $libdir = $::operatingsystem ? {
    /(Debian|Ubuntu)/ => '/usr/lib',
    default           => "/usr/${lib}",
  }
  $mail_to_default             = "root@${::fqdn}"
  $plugin_dir                  = "${libdir}/bareos"
  $storage_package             = 'bareos-storage'
  $storage_additional_packages = ['bareos-storage-python-plugin']
  $storage_server_default      = "bareos.${::domain}"
  $database_package_mysql      = 'bareos-database-mysql'
  $database_package_pgsql      = 'bareos-database-postgresql'
  $database_package_sqlite     = 'bareos-database-sqlite'

  # Client specific defaults
  $client_ensure = true
  $client_packages = ['bareos-filedaemon']
  $client_service_name = 'bareos-fd'
  $client_confdir = '/etc/bareos'
  $client_config_filename = 'bareos-fd.conf'
}
