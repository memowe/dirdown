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

use_ok 'Dirdown';

subtest 'Invalid arguments' => sub {
    my $no = Dirdown->new;
    throws_ok {$no->dir} qr/^No Dirdown directory 'dir' given\b/,
        'Correct dir exception';
};

my $content = Dirdown->new(dir => $dir, home => 'baz');

subtest 'Tree construction' => sub {
    isa_ok $content->tree   => 'Dirdown::Node', 'Tree';
    is $content->tree->dir  => $content->dir, 'Correct tree dir';
    is $content->tree->path => $content->tree->dir, 'Correct root path';

    # There's no way to test for pre-evaluation
    is_deeply $content->full_tree => $content->tree,
        'Correct pre-evaluated tree';
};

subtest 'Content search' => sub {
    is $content->content_for('') => $content->tree,
        "Directory listing for ''";
    is $content->content_for('xnorfzt') => undef, "Nothing found for 'xnorfzt'";

    subtest 'F_oo page' => sub {
        my $page = $content->content_for('F_oo');
        ok defined($page), 'Got something back';
        isa_ok $page => 'Dirdown::Page', 'Found page';
        is $page->dir => $content->dir, 'Correct content dir';
        is $page->path => $file_foo, 'Correct content path';
    };

    subtest 'bar/baz page' => sub {
        my $page = $content->content_for('bar/baz');
        ok defined($page), 'Got something back';
        isa_ok $page => 'Dirdown::Page', 'Found page';
        is $page->dir => $content->dir, 'Correct content dir';
        is $page->path => $file_baz, 'Correct content path';
    };

    subtest 'bar page' => sub {
        my $page = $content->content_for('bar');
        ok defined($page), 'Got something back';
        isa_ok $page => 'Dirdown::Page', 'Found page';
        is $page->dir => $content->dir, 'Correct content dir';
        is $page->path => $file_baz, 'Correct content path';
    };
};

subtest Navigation => sub {

    subtest Tree => sub {
        my $rt = $content->tree->children;
        my $nt = $content->navi_tree;

        subtest 'Full tree' => sub {
            ok defined($nt), 'Navi tree defined';
            is $nt->[0]{path} => 'F_oo', 'Correct first path';
            ok $nt->[0]{node}->equals($rt->[0]),
                'Correct first page';
            is $nt->[1]{path} => 'bar', 'Correct second path';
            ok $nt->[1]{node}->equals($rt->[1]),
                'Correct second dir';
            is $nt->[1]{children}[0]{path} => 'baz', 'Correct third path';
            ok $nt->[1]{children}[0]{node}->equals($rt->[1]->children->[0]),
                'Correct third page';
        };

        subtest 'Tree for...' => sub {

            is $content->navi_tree('xnorfzt') => undef, 'Unknown path: nothing';

            subtest 'First level' => sub {

                subtest '(empty)' => sub {
                    my $ntf = $content->navi_tree('');
                    ok defined($ntf), 'Navi tree defined';
                    is_deeply $ntf->[0] => $nt->[0], 'Same first entry';
                    ok not(exists $ntf->[1]{children}),
                        'Second without children';
                    is $ntf->[1]{path} => 'bar', 'Correct second path';
                    ok $ntf->[1]{node}->equals($nt->[1]{node}),
                        'Correct second node';
                };

                subtest 'F_oo' => sub {
                    my $ntf = $content->navi_tree('F_oo');
                    ok defined($ntf), 'Navi tree defined';
                    ok delete($ntf->[0]{active}), 'First entry active';
                    is_deeply $ntf->[0] => $nt->[0], 'Same first entry';
                    ok not(exists $ntf->[1]{children}),
                        'Second without children';
                    is $ntf->[1]{path} => 'bar', 'Correct second path';
                    ok $ntf->[1]{node}->equals($nt->[1]{node}),
                        'Correct second node';
                };

                subtest 'bar (home)' => sub {
                    my $ntf = $content->navi_tree('bar');
                    ok defined($nt), 'Navi tree defined';
                    ok delete($ntf->[1]{active}), 'Second entry active';
                    ok delete($ntf->[1]{children}[0]{active}), 'Leaf active';
                    is_deeply $ntf => $nt, 'Correct rest of the tree';
                };
            };

            subtest 'Second level' => sub {
                my $ntf = $content->navi_tree('bar/baz');
                ok defined($nt), 'Navi tree defined';
                ok delete($ntf->[1]{active}), 'Second entry active';
                ok delete($ntf->[1]{children}[0]{active}), 'Leaf active';
                is_deeply $ntf => $nt, 'Correct rest of the tree';
            };
        };
    };

    subtest Stack => sub {
        my $nt = $content->navi_tree;

        is $content->navi_stack('xnorfzt') => undef, 'Unknown path: nothing';

        subtest 'First level' => sub {

            subtest '(empty)' => sub {
                my $nst = $content->navi_stack('');
                ok defined($nst), 'Navi stack defined';
                is scalar(@$nst) => 1, 'Only 1 level';
                is scalar(@{$nst->[0]}) => 2, 'Two children';
                is_deeply $nst->[0][0] => $nt->[0], 'Same first entry';
                ok not(exists $nst->[0][1]{children}),
                    'Second without children';
                is $nst->[0][1]{path} => 'bar', 'Correct second path';
                ok $nst->[0][1]{node}->equals($nt->[1]{node}),
                    'Correct second node';

                is_deeply $content->navi_stack => $content->navi_stack(''),
                    'No path given is like empty string';
            };

            subtest 'F_oo' => sub {
                my $nst = $content->navi_stack('F_oo');
                ok defined($nst), 'Navi stack defined';
                is scalar(@$nst) => 1, 'Only 1 level';
                is scalar(@{$nst->[0]}) => 2, 'Two children';
                ok delete($nst->[0][0]{active}), 'First entry active';
                is_deeply $nst->[0][0] => $nt->[0], 'Same first entry';
                ok not(exists $nst->[0][1]{children}),
                    'Second without children';
                is $nst->[0][1]{path} => 'bar', 'Correct second path';
                ok $nst->[0][1]{node}->equals($nt->[1]{node}),
                    'Correct second node';
            };

            subtest 'bar' => sub {
                my $nst = $content->navi_stack('bar');
                ok defined($nst), 'Navi stack defined';
                is scalar(@$nst) => 2, 'Two levels deep';
                is scalar(@{$nst->[0]}) => 2, 'Two children';
                is_deeply $nst->[0][0] => $nt->[0], 'Correct first entry';
                ok delete($nst->[0][1]{active}), 'Second entry active';
                is $nst->[0][1]{path} => 'bar', 'Correct second path';
                ok $nst->[0][1]{node}->equals($nt->[1]{node}),
                    'Correct second node';
                is scalar(@{$nst->[1]}) => 1, 'Second level: 1 child';
                ok delete($nst->[1][0]{active}), 'Baz active (home)';
                is $nst->[1][0]{path} => 'baz', 'Correct baz path';
                ok $nst->[1][0]{node}->equals($nt->[1]{children}[0]{node}),
                    'Correct baz node';
            };
        };

        subtest 'Second level' => sub {
            is_deeply $content->navi_stack('bar/baz')
                => $content->navi_stack('bar'), 'Correct explicit home';
        };
    };
};

subtest Caching => sub {

    subtest 'Caching works by default' => sub {
        my $baz_content = $content->content_for('bar/baz')->content->{raw};
        $file_baz->spurt('# New baz');
        is $content->content_for('bar/baz')->content->{raw}
            => $baz_content, 'Old baz content';
        $content->refresh;
        is $content->content_for('bar/baz')->content->{raw}
            => '# New baz', 'New baz content';
        $file_baz->spurt($baz_content); # clean up
    };
};

done_testing;
