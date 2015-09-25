# == Class: bareos::director
#
# This class manages the Bacula director component
#
# === Parameters
#
# All <tt>bareos</tt> classes are called from the main <tt>::bareos</tt> class.  Parameters
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
class bareos::director (
  $backup_catalog        = true,
  $clients               = undef,
  $client_defaults       = undef,
  $console_password      = '',
  $db_backend            = 'sqlite',
  $db_database           = 'bareos',
  $db_host               = 'localhost',
  $db_password           = '',
  $db_port               = '3306',
  $db_user               = '',
  $db_user_host          = undef,
  $db_puppet_class       = undef,
  $dir_template          = 'bareos/bareos-dir.conf.erb',
  $director_password     = '',
  $director_server       = undef,
  $director_packages     = $::bareos::params::director_packages,
  $mail_to               = undef,
  $mail_to_daemon        = undef,
  $mail_to_on_error      = undef,
  $mail_to_operator      = undef,
  $manage_config_dir     = false,
  $manage_db             = false,
  $manage_db_tables      = true,
  $manage_logwatch       = undef,
  $plugin_dir            = undef,
  $storage_server        = undef,
  $tls_allowed_cn        = [],
  $tls_ca_cert           = undef,
  $tls_ca_cert_dir       = undef,
  $tls_cert              = undef,
  $tls_key               = undef,
  $tls_require           = 'yes',
  $tls_verify_peer       = 'yes',
  $use_console           = false,
  $use_tls               = false,
  $volume_autoprune      = 'Yes',
  $volume_autoprune_diff = 'Yes',
  $volume_autoprune_full = 'Yes',
  $volume_autoprune_incr = 'Yes',
  $volume_retention      = '1 Year',
  $volume_retention_diff = '40 Days',
  $volume_retention_full = '1 Year',
  $volume_retention_incr = '10 Days',
  $bareos_release        = undef,
) {
  include ::bareos::params

  $director_server_real = $director_server ? {
    undef   => $::bareos::params::director_server_default,
    default => $director_server,
  }

  # Allow <code>$mail_to_real</cdoe> to be <code>undef</code> only if <code>$mail_to_on_error</code> is supplied and set a default
  # if it isn't.
  if $mail_to_on_error {
    $mail_to_real = $mail_to
  } else {
    $mail_to_real = $mail_to ? {
      undef   => $::bareos::params::mail_to_default,
      default => $mail_to,
    }
  }

  # If <code>$mail_to_daemon</code> and / or <code>$mail_to_operator</code> is undefined set <code>_real</code> variables to be
  # either <code>$mail_to_real</code> or <code>$mail_to_on_error</code> in that order.
  if $mail_to_real {
    $mail_to_daemon_real   = $mail_to_daemon ? {
      undef   => $mail_to_real,
      default => $mail_to_daemon,
    }
    $mail_to_operator_real = $mail_to_operator ? {
      undef   => $mail_to_real,
      default => $mail_to_operator,
    }
  } elsif $mail_to_on_error {
    $mail_to_daemon_real   = $mail_to_daemon ? {
      undef   => $mail_to_on_error,
      default => $mail_to_daemon,
    }
    $mail_to_operator_real = $mail_to_operator ? {
      undef   => $mail_to_on_error,
      default => $mail_to_operator,
    }
  }

  $storage_server_real = $storage_server ? {
    undef   => $::bareos::params::storage_server_default,
    default => $storage_server,
  }

  if $clients != undef {
    # This function takes each client specified in <tt>$clients</tt>
    # and generates a <tt>bareos::client</tt> resource for each
    create_resources('bareos::client::config', $clients, $client_defaults)
  }

  package{ $director_packages:
    ensure => present,
  }

  $db_package = $db_backend ? {
    'mysql'      => $::bareos::params::database_package_mysql,
    'postgresql' => $::bareos::params::database_package_pgsql,
    default      => $::bareos::params::database_package_sqlite
  }

  package { $db_package:
    ensure  => present,
    require => Package[$director_packages],
  }

  $config_dir_source = $manage_config_dir ? {
    true    => 'puppet:///modules/bareos/bareos-empty.dir',
    default => undef,
  }

  # Create the configuration for the Director and make sure the directory for
  # the per-Client configuration is created before we run the realization for
  # the exported files below
  file { '/etc/bareos/bareos-dir.d':
    ensure  => directory,
    owner   => 'bareos',
    group   => 'bareos',
    mode    => '0750',
    purge   => $manage_config_dir,
    force   => $manage_config_dir,
    recurse => $manage_config_dir,
    source  => $config_dir_source,
    require => Package[$db_package],
    notify  => Exec['bareos-dir reload'],
  }

  file { '/etc/bareos/bareos-dir.d/empty.conf':
    ensure  => file,
    owner   => 'bareos',
    group   => 'bareos',
    mode    => '0640',
    content => '',
  }

  $file_requires = $plugin_dir ? {
    undef   => File[
      '/etc/bareos/bareos-dir.d',
      '/etc/bareos/bareos-dir.d/empty.conf',
      '/var/lib/bareos',
      '/var/log/bareos',
      '/var/spool/bareos',
      '/var/run/bareos'
    ],
    default => File[
      '/etc/bareos/bareos-dir.d',
      '/etc/bareos/bareos-dir.d/empty.conf',
      '/var/lib/bareos',
      '/var/log/bareos',
      '/var/spool/bareos',
      '/var/run/bareos',
      $plugin_dir
    ],
  }

  file { '/etc/bareos/bareos-dir.conf':
    ensure  => file,
    owner   => 'bareos',
    group   => 'bareos',
    mode    => '0640',
    content => template($dir_template),
    require => $file_requires,
    before  => Service['bareos-dir'],
    notify  => Exec['bareos-dir reload'],
  }

  if $backup_catalog {
    File["/etc/bareos/bareos-dir.d/${director_server_real}.conf"] -> File['/etc/bareos/bareos-dir.conf']
  }

  if $manage_db_tables {
    case $db_backend {
      'mysql'  : {
        class { '::bareos::director::mysql':
          db_database     => $db_database,
          db_user         => $db_user,
          db_password     => $db_password,
          db_port         => $db_port,
          db_host         => $db_host,
          db_user_host    => $db_user_host,
          manage_db       => $manage_db,
          db_puppet_class => $db_puppet_class,
          bareos_release  => $bareos_release,
        }
      }
      'sqlite' : {
        class { '::bareos::director::sqlite':
          db_database => $db_database,
        }
      }
      default  : {
        fail "The bareos module does not support managing the ${db_backend} backend database"
      }
    }
  }

  # Register the Service so we can manage it through Puppet
  if $manage_db_tables {
    $service_require = [
      Exec['make_db_tables'],
      File['/etc/bareos/bareos-dir.conf'],
    ]
  } else {
    $service_require = File['/etc/bareos/bareos-dir.conf']
  }

  service { 'bareos-dir':
    ensure     => running,
    name       => $::bareos::params::director_service,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => $service_require,
  }

  # Instead of restarting the <code>bareos-dir</code> service which could interrupt running jobs tell the director to reload its
  # configuration.
  exec { 'bareos-dir reload':
    command     => '/bin/echo reload | /usr/sbin/bconsole',
    logoutput   => on_failure,
    refreshonly => true,
    timeout     => 10,
    require     => [
      Class['::bareos::console'],
      Service['bareos-dir'],
    ],
  }
}
