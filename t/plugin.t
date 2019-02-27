#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojo::File 'tempdir';

### Prepare dirdown directory structure with content
my $dir         = tempdir;
my $file_foo    = $dir      ->child('1_F_oo.md')->spurt('# Foo');
my $dir_bar     = $dir      ->child('2_bar')->make_path;
my $file_baz    = $dir_bar  ->child('baz.md')->spurt('# B! A! Z!');
### Prepare web app
my $templates   = tempdir;
$templates->child('dirdown_page_debug.html.ep')->spurt(<<'TEMPLATE');
<p>test template</p>
%== $page->html
TEMPLATE
use Mojolicious::Lite;
use lib app->home->rel_file('../lib')->to_string;
plugin Dirdown => {
    prefix      => '/x',
    dir         => $dir,
    home        => 'baz',
    debug       => '/debug',
    templates   => $templates,
};
get '/' => {text => 'App with plugin'};
### End of preparations

local $ENV{MOJO_LOG_LEVEL} = 'error';
my $t = Test::Mojo->new;

subtest 'App route' => sub {
    $t->get_ok('/')->status_is(200)->content_is('App with plugin');
};

subtest Content => sub {
    $t->get_ok('/x')->status_is(404);
    $t->get_ok('/x/F_oo')->status_is(200)->text_is(h1 => 'Foo');
    $t->get_ok('/x/bar/baz')->status_is(200)->text_is(h1 => 'B! A! Z!');
    $t->get_ok('/x/bar')->status_is(200)->text_is(h1 => 'B! A! Z!');
};

subtest 'Custom templates' => sub {
    $t->get_ok('/x/F_oo')->status_is(200)->text_is(p => 'test template');
};

subtest Debug => sub {
    $t->get_ok('/x/debug')->status_is(200);
};

done_testing;
