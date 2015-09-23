# == Class: bareos::director::logwatch
#
# The EPEL <tt>bareos-director-common</tt> package requires <tt>logwatch</tt> and installs configs specifically for it.  Since we
# move the logs we should probably also update the <tt>logwatch</tt> configs as well.
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
class bareos::director::logwatch (
  $logwatch_enabled = true
) {
  Class['::bareos::director'] -> Class['::bareos::director::logwatch']

  $config_ensure = $logwatch_enabled ? {
    false   => absent,
    default => file,
  }

  file { '/etc/logwatch/conf/logfiles/bareos.conf':
    ensure  => $config_ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('bareos/logwatch/logfiles.conf.erb'),
  }

  file { '/etc/logwatch/conf/services/bareos.conf':
    ensure  => $config_ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('bareos/logwatch/services.conf.erb'),
  }

  $services_source = $::operatingsystem ? {
    /(Debian|Ubuntu)/ => 'puppet:///modules/bareos/logwatch/bareos.pl',
    default           => undef,
  }

  # Apparently the Ubuntu and Debian packages don't include the logwatch scripts so we'll need to provide them. The EPEL and Fedora
  # packages include the scripts so we'll allow the content to be updated with the rpms.
  file { '/etc/logwatch/scripts/services/bareos':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => $services_source,
  }

  $applybareosdate_source = $::operatingsystem ? {
    /(Debian|Ubuntu)/ => 'puppet:///modules/bareos/logwatch/applybareosdate.pl',
    default           => undef,
  }

  file { '/etc/logwatch/scripts/shared/applybareosdate':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => $applybareosdate_source,
  }
}
