#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojo::File 'path', 'tempdir';

# Silence
local $ENV{MOJO_LOG_LEVEL} = 'error';

### Prepare dirdown directory structure with content
my $dir         = tempdir;
my $file_foo    = $dir      ->child('1_F_oo.md')->spurt('# Foo');
my $dir_bar     = $dir      ->child('2_bar')->make_path;
my $file_baz    = $dir_bar  ->child('baz.md')->spurt('# B! A! Z!');
local $ENV{DIRDOWN_CONTENT} = $dir;

subtest 'Standard web app' => sub {
    my $t = do {
        local $ENV{DIRDOWN_PREFIX}          = '/x';
        local $ENV{DIRDOWN_DIRECTORYHOME}   = 'baz';
        Test::Mojo->new(path(__FILE__)->sibling('webapp'));
    };

    $t->get_ok('/x/debug')->status_is(404);

    subtest Content => sub {
        $t->get_ok('/x')->status_is(404);
        $t->get_ok('/x/F_oo')->status_is(200)->text_is(h1 => 'Foo');
        $t->get_ok('/x/bar/baz')->status_is(200)->text_is(h1 => 'B! A! Z!');
        $t->get_ok('/x/bar')->status_is(200)->text_is(h1 => 'B! A! Z!');
    };

    subtest Cache => sub {
        my $foo_content = $file_foo->slurp;
        $file_foo->spurt('# New foo');
        $t->get_ok('/x/F_oo')->text_is(h1 => 'Foo');
        $file_foo->spurt($foo_content);
    };
};

subtest Debug => sub {
    my $t = do {
        local $ENV{DIRDOWN_DEBUGROUTE} = '/xnorfzt';
        Test::Mojo->new(path(__FILE__)->sibling('webapp'));
    };

    subtest Route => sub {
        $t->get_ok('/pages/xnorfzt')->status_is(200)
            ->content_like(qr/$dir/)
            ->content_like(qr/$file_foo/)
            ->content_like(qr/$dir_bar/)
            ->content_like(qr/$file_baz/);
    };

    subtest 'Template extension' => sub {
        $t->get_ok('/pages/bar/baz')->status_is(200)
            ->text_like('#dirdown_debug_name strong' => qr/baz/)
            ->text_like('#dirdown_debug_name' => qr|2_bar/baz\.md|)
            ->text_is('#dirdown_debug_meta pre' => $t->app->dumper(
                $t->app->dirdown->content_for('bar/baz')->meta))
            ->text_is(h1 => 'B! A! Z!');
    };
};

subtest 'Custom templates' => sub {
    my $templates = tempdir;
    $templates->child('dirdown_page.html.ep')->spurt(<<'TEMPLATE');
<p>test template</p>
%== $page->html
TEMPLATE

    my $t = do {
        local $ENV{DIRDOWN_TEMPLATES} = $templates;
        Test::Mojo->new(path(__FILE__)->sibling('webapp'));
    };

    $t->get_ok('/pages/F_oo')->status_is(200)->text_is(p => 'test template');
};

subtest 'No cache' => sub {
    my $t = do {
        local $ENV{DIRDOWN_REFRESH} = 1;
        Test::Mojo->new(path(__FILE__)->sibling('webapp'));
    };

    my $foo_content = $file_foo->slurp;
    $file_foo->spurt('# New foo');
    $t->get_ok('/pages/F_oo')->text_is(h1 => 'New foo');
    $file_foo->spurt($foo_content);
};

done_testing;
