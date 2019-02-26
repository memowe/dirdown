#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Mojo::File 'tempdir';

### Prepare dirdown directory structure with content
my $dir         = tempdir;
my $file_foo    = $dir      ->child('1_F_oo.md')->spurt('# Foo');
my $dir_bar     = $dir      ->child('2_bar')->make_path;
my $file_baz    = $dir_bar  ->child('baz.md')->spurt('# Baz');
### Preparations done

use_ok 'Dirdown::Content';

subtest 'Invalid arguments' => sub {
    my $no = Dirdown::Content->new;
    throws_ok {$no->dir} qr/^No Dirdown directory 'dir' given\b/,
        'Correct dir exception';
};

my $content = Dirdown::Content->new(dir => $dir);

subtest 'Tree construction' => sub {
    isa_ok $content->tree   => 'Dirdown::Content::Node', 'Tree';
    is $content->tree->dir  => $content->dir, 'Correct tree dir';
    is $content->tree->path => $content->tree->dir, 'Correct root path';

    # There's no way to test for pre-evaluation
    is_deeply $content->full_tree => $content->tree,
        'Correct pre-evaluated tree';
};

subtest 'Content search' => sub {
    ok 1; # TODO
};

done_testing;
