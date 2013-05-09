# Class: cassandra
#
# This class installs Apache Cassandra
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class cassandra (
  $version        = $cassandra::params::version,
  $cassandra_home = $cassandra::params::cassandra_home,
  $source_file    = undef,
  $source         = $cassandra::params::source,
  $cluster_name   = undef,
  $seed_nodes     = undef,
) inherits cassandra::params{

  include '::java'
  include 'staging'

  if $source_file {
    $filename = $source_file
  } else {
    $filename = "apache-cassandra-${version}-bin.tar.gz"
  }

  if $cluster_name {
    $cluster = $cluster_name
  } else {
    $cluster = 'Test Cluster'
  }

  if $seed_nodes {
    $seeds = flatten([$seed_nodes])
  } else {
    $seeds = ['127.0.0.1']
  }

  staging::deploy { $filename:
    target  => '/opt',
    creates => "/opt/apache-cassandra-${version}",
    source  => "${source}/${filename}",
  }

  file { $cassandra_home:
    ensure  => link,
    target  => "/opt/apache-cassandra-${version}",
    require => Staging::Extract[$filename],
  }

  file { [
    '/var/lib/cassandra',
    '/var/lib/cassandra/data',
    '/var/lib/cassandra/commitlog',
    '/var/lib/cassandra/saved_caches',
    '/var/log/cassandra'
  ]:
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => File[$cassandra_home],
  }

  file { '/usr/local/bin/cassandra-cli':
    ensure  => link,
    target  => "${cassandra_home}/bin/cassandra-cli",
    require => File[$cassandra_home],
  }

  file { '/etc/init.d/cassandra':
    ensure  => present,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template('cassandra/cassandra_init.erb'),
    require => File[$cassandra_home],
  }

  file { '/opt/cassandra/conf/cassandra.yaml':
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('cassandra/cassandra_yaml.erb'),
    require => File[$cassandra_home],
    notify  => Service["cassandra"],
  }

  class { 'cassandra::service':
    ensure    => running,
    require   => [
      Class['java'],
      File['/etc/init.d/cassandra'],
    ]
  }
}
