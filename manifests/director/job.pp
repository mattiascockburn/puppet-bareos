# == Define: bareos::job
# adjusted by Mattias Giese, giese@b1-systems.de
#
# Install a config file describing a client job on the director.
#
# === Parameters
#
# [*ensure*]
#   If the configuration should be deployed to the director. <code>file</code> (default), <code>present</code>, or
#   <code>absent</code>.
# [*backup_enable*]
#   If the backup job for the client should be enabled <code>'yes'</code> (default) or <code>'no'</code>.
# [*client_schedule*]
#   The schedule for backups to be performed.
# [*db_backend*]
#   The database backend of the catalog storing information about the backup
# [*director_password*]
#   The director's password the client is connecting to.
# [*director_server*]
#   The FQDN of the director server the client will connect to.
# [*fileset*]
#   The file set used by the client for backups
# [*pool*]
#   The pool used by the client for backups
# [*pool_diff*]
#   The pool to use for differential backups. Setting this to <code>false</code> will prevent configuring a specific pool for
#   differential backups. Defaults to <code>"${pool}.differential"</code>.
# [*pool_full*]
#   The pool to use for full backups. Setting this to <code>false</code> will prevent configuring a specific pool for full backups.
#   Defaults to <code>"${pool}.full"</code>.
# [*pool_incr*]
#   The pool to use for incremental backups. Setting this to <code>false</code> will prevent configuring a specific pool for
#   incremental backups. Defaults to <code>"${pool}.incremental"</code>.
# [*priority*]
#   This directive permits you to control the order in which your jobs will be run by specifying a positive non-zero number. The
#   higher the number, the lower the job priority. Assuming you are not running concurrent jobs, all queued jobs of priority
#   <code>1</code> will run before queued jobs of priority <code>2</code> and so on, regardless of the original scheduling order.
#   The priority only affects waiting jobs that are queued to run, not jobs that are already running. If one or more jobs of
#   priority <code>2</code> are already running, and a new job is scheduled with priority <code>1</code>, the currently running
#   priority <code>2</code> jobs must complete before the priority <code>1</code> job is run, unless <code>Allow Mixed
#   Priority</code> is set. The default priority is <code>10</code>.
# [*rerun_failed_levels*]
#   If this directive is set to <code>'yes'</code> (default <code>'no'</code>), and Bacula detects that a previous job at a higher
#   level (i.e. Full or Differential) has failed, the current job level will be upgraded to the higher level. This is particularly
#   useful for Laptops where they may often be unreachable, and if a prior Full save has failed, you wish the very next backup to be
#   a Full save rather than whatever level it is started as. There are several points that must be taken into account when using
#   this directive: first, a failed job is defined as one that has not terminated normally, which includes any running job of the
#   same name (you need to ensure that two jobs of the same name do not run simultaneously); secondly, the Ignore FileSet Changes
#   directive is not considered when checking for failed levels, which means that any FileSet change will trigger a rerun.
# [*restore_enable*]
#   If the restore job for the client should be enabled <code>'yes'</code> (default) or <code>'no'</code>.
# [*restore_where*]
#   The default path to restore files to defined in the restore job for this client.
# [*run_scripts*]
#   An array of hashes containing the parameters for any
#   {RunScripts}[http://www.bareos.org/5.0.x-manuals/en/main/main/Configuring_Director.html#6971] to include in the backup job
#   definition. For each hash in the array a <code>RunScript</code> directive block will be inserted with the
#   <code>key = value</code> settings from the hash.  Note: The <code>RunsWhen</code> key is required.
# [*storage_server*]
#   The storage server hosting the pool this client will backup to
# [*tls_ca_cert*]
#   The full path and filename specifying a PEM encoded TLS CA certificate(s). Multiple certificates are permitted in
#   the file. One of <code>TLS CA Certificate File</code> or <code>TLS CA Certificate Dir</code> are required in a server context if
#   <code>TLS Verify Peer</code> is also specified, and are always required in a client context.
# [*tls_ca_cert_dir*]
#   Full path to TLS CA certificate directory. In the current implementation, certificates must be stored PEM
#   encoded with OpenSSL-compatible hashes, which is the subject name's hash and an extension of .0. One of
#   <code>TLS CA Certificate File</code> or <code>TLS CA Certificate Dir</code> are required in a server context if
#   <code>TLS Verify Peer</code> is also specified, and are always required in a client context.
# [*use_tls*]
#   Whether to use {Bacula TLS - Communications
#   Encryption}[http://www.bareos.org/en/dev-manual/main/main/Bacula_TLS_Communications.html].
#
# === Examples
#
#   bareos::client::config { 'client1.example.com' :
#     client_schedule   => 'WeeklyCycle',
#     db_backend        => 'mysql',
#     director_password => 'directorpassword',
#     director_server   => 'bareos.example.com',
#     fileset           => 'Basic:noHome',
#     pool              => 'otherpool',
#     storage_server    => 'bareos.example.com',
#   }
#
# === Copyright
#
# Copyright 2012-2013 Russell Harrison
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
define bareos::director::job (
  $ensure         = file,
  $client         = undef,
  $enable         = 'yes',
  $jobname        = $name,
  $type           = undef,
  $job_schedule   = 'WeeklyCycle',
  $fileset        = undef,
  $pool           = 'default',
  $pool_diff      = undef,
  $pool_full      = undef,
  $pool_incr      = undef,
  $priority       = undef,
  $restore_where  = '/var/tmp/bareos-restores',
  $run_scripts    = undef,
  $rerun_when_failed = 'no',
  $storage_server = undef,
) {
  include ::bareos::params

  validate_string($jobname)
  validate_string($type,'^(Restore|Backup)$')

  if !is_domain_name($client) {
    fail "Name for client ${client} must be a fully qualified domain name"
  }

  validate_re($enable, '^(yes|Yes|no|No)$')

  case $director_password {
    ''      : {
      $director_password_real = $::bareos::director::director_password ? {
        undef   => '',
        default => $::bareos::director::director_password,
      }
    }
    default : {
      $director_password_real = $director_password
    }
  }

  case $director_server {
    undef   : {
      $director_server_real = $::bareos::director::director_server ? {
        undef   => $::bareos::params::director_server_default,
        default => $::bareos::director::director_server,
      }
    }
    default : {
      $director_server_real = $director_server
    }
  }

  if !is_domain_name($director_server_real) {
    fail "director_server=${director_server_real} must be a fully qualified domain name"
  }
  validate_absolute_path($restore_where)

  $pool_diff_real = $pool_diff ? {
    undef   => "${pool}.differential",
    default => $pool_diff,
  }

  $pool_full_real = $pool_full ? {
    undef   => "${pool}.full",
    default => $pool_full,
  }

  $pool_incr_real = $pool_incr ? {
    undef   => "${pool}.incremental",
    default => $pool_incr,
  }

  if !($rerun_when_failed in ['yes', 'no']) {
    fail("rerun_when_failed = ${rerun_when_failed} must be either 'yes' or 'no'")
  }

  if $run_scripts {
    case type($run_scripts) {
      'array' : {
        # TODO figure out how to validate each item in the array is a hash.
        $run_scripts_real = $run_scripts
      }
      'hash'  : {
        $run_scripts_real = [$run_scripts]
      }
      default : {
        fail("run_scripts = ${run_scripts} must be an array of hashes or a hash")
      }
    }
  }

  case $storage_server {
    undef   : {
      $storage_server_real = $::bareos::director::storage_server ? {
        undef   => $::bareos::params::storage_server_default,
        default => $::bareos::director::storage_server,
      }
    }
    default : {
      $storage_server_real = $storage_server
    }
  }

  if !is_domain_name($storage_server_real) {
    fail "storage_server=${storage_server_real} must be a fully qualified domain name"
  }

  file { "${::bareos::params::director_confd}/job-${name}.conf":
    ensure  => $ensure,
    owner   => $::bareos::params::config_owner,
    group   => $::bareos::params::config_group,
    mode    => $::bareos::params::config_file_mode,
    content => template('bareos/director/job.erb'),
    before  => Service[$::bareos::params::director_service],
    notify  => Exec['bareos-dir reload'],
  }
}
