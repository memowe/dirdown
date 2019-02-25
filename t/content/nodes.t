#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Mojo::File 'tempdir';
use Mojo::Util 'encode';

### Prepare dirdown directory structure with content
my $dir         = tempdir;
my $file_foo    = $dir      ->child('1_F_oo.md')->spurt('# Foo');
my $dir_bar     = $dir      ->child('2_bar')->make_path;
my $file_baz    = $dir_bar  ->child('baz.md')->spurt(encode 'UTF-8' => <<'MD');
answer: 42
name: Es ist schön
---
# B! A! Z!
MD
### Preparations done

subtest Node => sub {
    use_ok 'Dirdown::Content::Node';

    subtest 'Invalid arguments' => sub {
        my $no = Dirdown::Content::Node->new;
        throws_ok {$no->dir} qr/^No 'dir' given\b/, 'Correct dir exception';
        throws_ok {$no->path} qr/^No 'path' given\b/, 'Correct path exception';
    };

    my $node = Dirdown::Content::Node->new(dir => $dir, path => $file_foo);
    isa_ok $node => 'Dirdown::Content::Node', 'Constructed node object';
};

done_testing;
