#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;

use Mojo::File qw(path tempdir);
use Mojolicious::Command::Author::generate::dirdown_app;

use_ok 'Dirdown::Command::dump';
my $dcd = Dirdown::Command::dump->new;

subtest Basics => sub {
    is $dcd->description => 'Generate static files from a dirdown app',
        'Correct description';
    like $dcd->usage => qr/^Usage: dirdown_app dump/,
        'Correct usage start';
};

subtest Generate => sub {

    # Create dirdown app
    my $cwd = path;
    my $dir = tempdir;
    chdir $dir;
    Mojolicious::Command::Author::generate::dirdown_app->new->run;

    # Add custom content
    my $content = $dir->child('dirdown_content')->remove_tree({keep_root => 1});
    $content->child('index.md')->spurt('# Sitemap');
    $content->child('foo.md')->spurt('# Foo');
    $content->child('bar')->make_path->child('baz.md')->spurt('# Baz');

    # Prepare app and dump
    require $dir->child('dirdown');
    my $t = Test::Mojo->new;
    $t->app->start('dump');
    chdir $cwd;
    my $dd = $dir->child('dump');

    subtest 'Generated tree' => sub {
        ok -d $dd, 'Dump directory exists';
        ok -e $dd->child('answer.txt'), 'Static file exists';
        ok -e $dd->child($_), "$_ exists"
            for qw(index.html foo.html bar/baz.html);
    };

    subtest Content => sub {
        $t->get_ok('/index')->content_is($dd->child('index.html')->slurp);
        $t->get_ok('/foo')->content_is($dd->child('foo.html')->slurp);
        $t->get_ok('/bar/baz')->content_is($dd->child('bar/baz.html')->slurp);
        $t->get_ok('/answer.txt')->content_is($dd->child('answer.txt')->slurp);
    };
};

done_testing;
