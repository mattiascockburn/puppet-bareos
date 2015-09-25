# == Class: bareos::director::mysql
#
# Manage MySQL resources for the Bacula director.
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
class bareos::director::mysql (
  $db_database         = 'bareos',
  $db_host             = 'localhost',
  $db_password         = '',
  $db_port             = '3306',
  $db_user             = '',
  $db_user_host        = undef,
  $manage_db           = false,
  $db_puppet_class     = '::mysql::server',
  $mysql_57_workaround = false,
  $bareos_release      = undef,
) {
  include ::bareos::params

  validate_string($db_database)
  validate_string($db_host)
  validate_string($db_password)
  validate_string($db_port)
  validate_string($db_user)
  validate_string($db_user_host)
  validate_bool($manage_db)
  validate_string($db_puppet_class)

  if $manage_db {
    if defined(Class[$db_puppet_class]) {
        $db_require = Class[$db_puppet_class]
    }
    else {
      $db_require = undef
    }

    $db_user_host_real = $db_user_host ? {
      undef   => $::fqdn,
      default => $db_user_host,
    }

    # This is more than just ugly 
    if $mysql_57_workaround {
      file{'BareOS MySQL 5.7 Workaround':
        ensure => file,
        path   => '/usr/lib/bareos/scripts/ddl/creates/mysql.sql',
        source => "puppet:///modules/bareos/mysql-${bareos_release}-fix.sql",
        before => Exec['make_db_tables'],
      }
    }

    #FIXME Due to a bug in v1.0.0 of the puppetlabs-mysql module I can't use a notify here on the define.
    mysql::db { $db_database:
      user     => $db_user,
      password => $db_password,
      host     => $db_user_host,
      grant    => ['all'],
      require  => $db_require,
      # notify    => Exec['make_db_tables'],
      before   => Exec['make_db_tables'],
    }
    #FIXME Work around a bug in v1.0.0 of the puppetlabs-mysql module that causes the <code>mysql_grant</code> type to notify on
    # every run by having the <code>mysql_database</code> resource created in the <code>mysql::db</code> define notify
    # <code>Exec['make_db_tables']</code> instead of using the more flexible notify from the entire define.
    Mysql_database[$db_database] ~> Exec['make_db_tables']
  }
  $make_db_tables_command = '/usr/lib/bareos/scripts/make_bareos_tables'
  if $::bareos::db_backend == 'mysql' { 
    $db_parameters = "$::bareos::db_backend -u ${db_user} --password=${db_password}"
  }
  else {
    $db_parameters = "$::bareos::db_backend"
  }

  exec { 'make_db_tables':
    command     => "${make_db_tables_command} ${db_parameters}",
    refreshonly => true,
    logoutput   => true,
    #require     => Package[$::bareos::params::database_package_mysql],
    before      => Service['bareos-dir'],
  }
}
