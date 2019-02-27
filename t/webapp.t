#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojo::File 'tempdir';

# No logs in this test, please
local $ENV{MOJO_LOG_LEVEL} = 'error';

subtest 'Default operations' => sub {
    my $t = Test::Mojo->new('Dirdown');
    $t->get_ok('/debug')->status_is(404); # No debug route
    like $t->app->dirdown->dir => qr|dirdown_content$|, 'Default dirdown dir';
};

subtest Configured => sub {

    ### Prepare dirdown directory structure with content
    my $dir         = tempdir;
    my $file_foo    = $dir      ->child('1_F_oo.md')->spurt('# Foo');
    my $dir_bar     = $dir      ->child('2_bar')->make_path;
    my $file_baz    = $dir_bar  ->child('baz.md')->spurt('# B! A! Z!');

    ### Preparations done

    local $ENV{DIRDOWN_CONTENT}         = $dir;
    local $ENV{DIRDOWN_DEBUGROUTE}      = '/xnorfzt';
    local $ENV{DIRDOWN_DIRECTORYHOME}   = 'baz';
    my $t = Test::Mojo->new('Dirdown');

    subtest Debug => sub {

        subtest Route => sub {
            $t->get_ok('/xnorfzt')->status_is(200)
                ->content_like(qr/$dir/)
                ->content_like(qr/$file_foo/)
                ->content_like(qr/$dir_bar/)
                ->content_like(qr/$file_baz/);
        };

        subtest 'Template extension' => sub {
            $t->get_ok('/bar')->status_is(200)
                ->text_like('#dirdown_debug_name strong' => qr/baz/)
                ->text_like('#dirdown_debug_name' => qr|2_bar/baz\.md|)
                ->text_is('#dirdown_debug_meta pre' => $t->app->dumper(
                    $t->app->dirdown->content_for('bar')->meta))
                ->text_is(h1 => 'B! A! Z!');
        };
    };

    subtest Content => sub {
        $t->get_ok('/')->status_is(404);
        $t->get_ok('/F_oo')->status_is(200)->text_is(h1 => 'Foo');
        $t->get_ok('/bar/baz')->status_is(200)->text_is(h1 => 'B! A! Z!');
        $t->get_ok('/bar')->status_is(200)->text_is(h1 => 'B! A! Z!');
    };
};

done_testing;
