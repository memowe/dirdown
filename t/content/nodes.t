#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Mojo::Path;
use Mojo::File 'tempdir';
use Mojo::Util 'encode';
use Text::Markdown 'markdown';

### Prepare dirdown directory structure with content
my $dir         = tempdir;
my $file_foo    = $dir      ->child('1_F_oo.md')->spurt('# Foo');
my $dir_bar     = $dir      ->child('2_bar')->make_path;
my $file_baz    = $dir_bar  ->child('baz.md')->spurt(encode 'UTF-8' => <<'MD');
answer: 42
name: Es ist schön
---
# B! Ä! Z!
MD
### Preparations done

subtest Node => sub {
    use_ok 'Dirdown::Node';

    subtest 'Invalid arguments' => sub {
        my $no = Dirdown::Node->new;
        throws_ok {$no->dir} qr/^No 'dir' given\b/, 'Correct dir exception';
        throws_ok {$no->path} qr/^No 'path' given\b/, 'Correct path exception';
    };

    subtest 'File foo' => sub {

        my $node = Dirdown::Node->new(dir => $dir, path => $file_foo);
        isa_ok $node => 'Dirdown::Node', 'Constructed node object';

        subtest 'Basic data' => sub {
            is $node->rel_path => '1_F_oo.md', 'Correct rel_path';
            is_deeply $node->path_parts => ['1_F_oo.md'], 'Correct path parts';
            is $node->basename => '1_F_oo.md', 'Correct basename';
            is $node->sort_val => 1, 'Correct sort value';
            is $node->path_name => 'F_oo', 'Correct path name';
        };

        subtest 'Tree data' => sub {
            isa_ok $node->children, 'Mojo::Collection', 'Children';
            is $node->children->size => 0, 'No Children';
        };
    };

    subtest 'Directory bar' => sub {

        my $node = Dirdown::Node->new(dir => $dir, path => $dir_bar);
        isa_ok $node => 'Dirdown::Node', 'Constructed node object';

        subtest 'Basic data' => sub {
            is $node->rel_path => '2_bar', 'Correct rel_path';
            is_deeply $node->path_parts => ['2_bar'], 'Correct path parts';
            is $node->basename => '2_bar', 'Correct basename';
            is $node->sort_val => 2, 'Correct sort value';
            is $node->path_name => 'bar', 'Correct path name';
        };

        subtest 'Tree data' => sub {
            isa_ok $node->children, 'Mojo::Collection', 'Children';
            is $node->children->size => 1, 'One child';
            my $child = $node->children->[0];
            isa_ok $child, 'Dirdown::Page', 'First child';
            is $child->path => $file_baz, 'Correct child path';
        };

        subtest 'Content lookup' => sub {
            is $node->content_for(undef) => $node, 'Node listing for undef';
            is $node->content_for('') => $node, "Node listing for ''";
            my $child = $node->content_for('baz');
            isa_ok $child => 'Dirdown::Page', "'baz' child";
            is $child->path => $file_baz, 'Correct child path';
        };

        subtest 'Navi tree' => sub {

            subtest Full => sub {
                my $fnt = $node->navi_tree('');
                ok defined($fnt), 'Full navi tree defined';
                is scalar(@$fnt) => 1, 'One child found';
                ok $fnt->[0]{node}->equals($node->children->[0]),
                    'Correct child';
            };

            subtest Partial => sub {
                my $fnt = $node->navi_tree('', ['baz']);
                ok defined($fnt), 'Full navi tree defined';
                ok delete($fnt->[0]{active}), 'Child is active';
                is_deeply $fnt => $node->navi_tree(''), "That's it";
            };
        };
    };

    subtest 'File baz' => sub {

        my $node = Dirdown::Node->new(dir => $dir, path => $file_baz);
        isa_ok $node => 'Dirdown::Node', 'Constructed node object';

        subtest 'Basic data' => sub {
            is $node->rel_path => '2_bar/baz.md', 'Correct rel_path';
            is_deeply $node->path_parts => ['2_bar', 'baz.md'],
                'Correct path parts';
            is $node->basename => 'baz.md', 'Correct basename';
            is $node->sort_val => 0, 'Correct sort value';
            is $node->path_name => 'baz', 'Correct path name';
        };

        subtest 'Tree data' => sub {
            isa_ok $node->children, 'Mojo::Collection', 'Children';
            is $node->children->size => 0, 'No Children';
        };
    };

    subtest 'Directory home' => sub {
        my $dir = Dirdown::Node->new(
            dir => $dir, path => $dir_bar, home => 'baz'
        );
        is $dir->content_for('') => $dir->content_for('baz'),
            'Correct directory home';
    };

    subtest Equality => sub {
        my ($p1, $p2, $p3) = map {
            Dirdown::Node->new(dir => $dir, path => $_)
        } $dir_bar, $dir_bar, $file_baz;

        ok $p1->equals($p2), 'Same path';
        ok $p2->equals($p1), 'Same path, the other way round';
        ok not($p1->equals($p3)), 'Different path';
        ok not($p3->equals($p1)), 'Different path, the other way round';

        $p1->dir(Mojo::Path->new('xnorfzt'));
        ok not($p1->equals($p2)), 'Different dir';
    };

    subtest 'Copy constructor' => sub {
        my $node = Dirdown::Node->new(
            dir => $dir, path => $dir_bar);
        my $clone = $node->clone;
        isa_ok $clone => 'Dirdown::Node', 'Cloned node';
        ok $clone->equals($node), '"Equal"';
        ok $clone != $node, 'Not the same';
    };
};

subtest Page => sub {
    isa_ok 'Dirdown::Page' => 'Dirdown::Node';

    subtest 'File foo' => sub {

        my $page = Dirdown::Page->new(dir => $dir, path => $file_foo);
        isa_ok $page => 'Dirdown::Page', 'Constructed page object';

        is_deeply $page->content => {
            raw         => '# Foo',
            yaml        => '',
            markdown    => '# Foo',
        }, 'Correct content parts';

        is_deeply $page->meta => {}, 'Correct yaml meta data';
        is $page->html => markdown('# Foo'), 'Correct markdown generated HTML';
        is $page->name => 'F oo', 'Correct page name';
        is $page->content_for('xnorfzt') => undef, "No content for 'xnorfzt'";
        is $page->content_for('') => $page, 'A page is its own empty content';
    };

    subtest 'File baz' => sub {

        my $page = Dirdown::Page->new(dir => $dir, path => $file_baz);
        isa_ok $page => 'Dirdown::Page', 'Constructed page object';

        subtest 'Raw content' => sub {
            my $raw = "answer: 42\nname: Es ist schön\n---\n# B! Ä! Z!\n";
            my ($yaml, $markdown) = split /---/ => $raw;
            is_deeply $page->content => {
                raw      => $raw,
                yaml     => $yaml,
                markdown => $markdown,
            }, 'Correct content parts';
        };

        is_deeply $page->meta => {answer => 42, name => "Es ist schön"},
            'Correct yaml meta data';
        is $page->html => markdown('# B! Ä! Z!'), 'Correct generated HTML';
        is $page->name => 'Es ist schön', 'Correct page name';
        is $page->content_for('xnorfzt') => undef, "No content for 'xnorfzt'";
        is $page->content_for('') => $page, 'A page is its own empty content';
    };

    subtest Equality => sub {
        my ($p1, $p2, $p3) = map {
            Dirdown::Page->new(dir => $dir, path => $_)
        } $file_foo, $file_foo, $file_baz;

        ok $p1->equals($p2), 'Same path';
        ok $p2->equals($p1), 'Same path, the other way round';
        ok not($p1->equals($p3)), 'Different path';
        ok not($p3->equals($p1)), 'Different path, the other way round';
    };

    subtest 'Copy constructor' => sub {
        my $node = Dirdown::Page->new(
            dir => $dir, path => $file_foo);
        my $clone = $node->clone;
        isa_ok $clone => 'Dirdown::Page', 'Cloned page';
        ok $clone->equals($node), '"Equal"';
        ok $clone != $node, 'Not the same';
    };
};

done_testing;
