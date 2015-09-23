class { '::bareos':
  is_storage        => true,
  is_director       => true,
  is_client         => true,
  manage_console    => true,
  director_password => 'XXXXXXXXX',
  console_password  => 'XXXXXXXXX',
  director_server   => 'bareos.domain.com',
  mail_to           => 'bareos-admin@domain.com',
  storage_server    => 'bareos.domain.com',
}
