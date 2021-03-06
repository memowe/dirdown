#!/usr/bin/env perl

use Mojo::Base -strict, -signatures;
use Test::More;
use Test::Mojo;
use Mojo::File 'path';

my $t = Test::Mojo->new(path(__FILE__)->sibling('webapp'));

subtest 'Relative paths' => sub {
    my $r = sub ($url, $base) {$t->app->rel_path($url, $base)};

    subtest 'Same level' => sub {
        is $r->('', '') => './', 'Empty paths';
        is $r->('foo', 'bar') => 'foo.html', 'Single words';
        is $r->('foo/bar', 'foo/baz'), 'bar.html', 'Deep paths';
    };

    subtest Complex => sub {
        is $r->('foo', 'bar/baz') => '../foo.html', '../foo';
        is $r->('foo/bar', 'foo') => 'foo/bar.html', '../foo/bar';
        is $r->('foo/bar', 'foo/') => 'bar.html', '../../foo/bar';
    };

    subtest 'Leading slashes' => sub {
        is $r->('/foo', 'bar/baz') => $r->('foo', 'bar/baz'), 'First';
        is $r->('foo', '/bar/baz') => $r->('foo', 'bar/baz'), 'Second';
    };

    subtest 'Non-HTML files' => sub {
        is $r->('/a/b/c.css', 'a/x/y.z') => '../b/c.css', 'css';
        is $r->('x.jpg', '/a/b/c') => '../../x.jpg', 'jpg';
    };
};

done_testing;
