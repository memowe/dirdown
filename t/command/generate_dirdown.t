#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Mojo::File qw(path tempdir);

use_ok 'Mojolicious::Command::Author::generate::dirdown_app';
my $gda = Mojolicious::Command::Author::generate::dirdown_app->new;

subtest Basics => sub {
    is $gda->description => 'Generate Dirdown directory structure',
        'Correct description';
    like $gda->usage => qr/^Usage: mojo generate dirdown_app/,
        'Correct usage start';
};

subtest Generate => sub {
    my $cwd = path;
    my $dir = tempdir;
    chdir $dir;

    # Resource files
    require Dirdown;
    my $res  = path($INC{'Dirdown.pm'})->dirname->child('Dirdown', 'resources');
    my $ress = $res->list_tree->map(to_rel => $res);

    # Generate
    $gda->run;

    subtest Content => sub {
        my $gens = path($dir)->list_tree->map(to_rel => $dir);
        is_deeply $gens => $ress, 'Correct structure';
        is_deeply $gens->map('slurp') => $ress->map('slurp'),
            'Correct file contents';
    };

    ok -x path($dir, 'dirdown'), 'Web app is executable';

    chdir $cwd;
};

done_testing;
