#!/bin/sh
exec perl -x "$0" "$@"
#!perl

use strict;
use warnings;
use lib 'lib';

use YAML;
use Uninets::WebChat::Schema;

# configure
my $config_file = 'config.yml';
my $default_config = {
    database => {
        driver => 'Pg',
        dbuser => 'webchat',
        dbname => 'webchat',
        dbpass => 'webchat',
        dbhost => 'localhost',
    },
    session_secret   => 'dQiGD3lE0CUwPQAXAod9hhi6sBSV0DqQDIWoPCd0Ukglu6NiA2maJWhVxfWPH05',
    keep_alive_token => '5a3a3316a166242932ea754c25',
    loglevel         => 'info',
};

my $config = {};

if ( -f $config_file ){
    $config =  YAML::LoadFile($config_file);
}
else {
    $config = $default_config;
}

my $dsn = 'dbi:' . $config->{database}->{driver} . ':dbname=' . $config->{database}->{dbname} . ';host=' . $config->{database}->{dbhost};
my $schema = Uninets::WebChat::Schema->connect($dsn, $config->{database}->{dbuser}, $config->{database}->{dbpass});
$schema->deploy;

# default admin:password
$schema->resultset('Role')->create({ name => 'admin', id => 1 });
$schema->resultset('User')->create({ login => 'admin', email => 'admin@example.com', role_id => 1, password => '$6$salt$IxDD3jeSOb5eB1CX5LBsqZFVkJdido3OUILO5Ifz5iwMuTS4XMS130MTSuDDl3aCI6WouIL9AjRbLCelDCy.g.'});

