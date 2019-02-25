#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;

### Web app
use Mojolicious::Lite -signatures;
use lib app->home->rel_file('../lib')->to_string;
plugin Dirdown => {debug => '/debug'};
get '/' => {text => 'App with plugin'};
### End of web app

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('App with plugin');

# TODO

done_testing;
