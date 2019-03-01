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

my $content = Dirdown::Content->new(dir => $dir, home => 'baz');

subtest 'Tree construction' => sub {
    isa_ok $content->tree   => 'Dirdown::Content::Node', 'Tree';
    is $content->tree->dir  => $content->dir, 'Correct tree dir';
    is $content->tree->path => $content->tree->dir, 'Correct root path';

    # There's no way to test for pre-evaluation
    is_deeply $content->full_tree => $content->tree,
        'Correct pre-evaluated tree';
};

subtest 'Content search' => sub {
    is $content->content_for('') => undef, "Nothing found for ''";
    is $content->content_for('xnorfzt') => undef, "Nothing found for 'xnorfzt'";

    subtest 'F_oo page' => sub {
        my $page = $content->content_for('F_oo');
        ok defined($page), 'Got something back';
        isa_ok $page => 'Dirdown::Content::Page';
        is $page->dir => $content->dir, 'Correct content dir';
        is $page->path => $file_foo, 'Correct content path';
    };

    subtest 'bar/baz page' => sub {
        my $page = $content->content_for('bar/baz');
        ok defined($page), 'Got something back';
        isa_ok $page => 'Dirdown::Content::Page';
        is $page->dir => $content->dir, 'Correct content dir';
        is $page->path => $file_baz, 'Correct content path';
    };

    subtest 'bar page' => sub {
        my $page = $content->content_for('bar');
        ok defined($page), 'Got something back';
        isa_ok $page => 'Dirdown::Content::Page';
        is $page->dir => $content->dir, 'Correct content dir';
        is $page->path => $file_baz, 'Correct content path';
    };
};

subtest Navigation => sub {

    subtest Tree => sub {

        subtest 'Full tree' => sub {
            my $nt = $content->navi_tree;
            my $rt = $content->tree;
            ok defined($nt), 'Navi tree defined';
            is $nt->[0]{path} => 'F_oo', 'Correct first path';
            ok $nt->[0]{node}->equals($rt->children->[0]),
                'Correct first page';
            is $nt->[1]{path} => 'bar', 'Correct second path';
            ok $nt->[1]{node}->equals($rt->children->[1]),
                'Correct second dir';
            is $nt->[1]{children}[0]{path} => 'baz', 'Correct third path';
            ok $nt->[1]{children}[0]{node}
                ->equals($rt->children->[1]->children->[0]),
                'Correct third page';
        };

        subtest 'Tree for...' => sub {

            subtest Nothing => sub {
                is $content->navi_tree_for(undef) => undef, 'undef';
                is $content->navi_tree_for('xnorfzt') => undef, 'Unknown path';
            };

            subtest 'First level' => sub {
                ok 1; # TODO
            };

            subtest 'Second level' => sub {
                ok 1; # TODO
            };
        };
    };

    subtest Stack => sub {
        ok 1; # TODO
    };
};

done_testing;
