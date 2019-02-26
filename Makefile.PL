use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    VERSION             => '0.1',
    MIN_PERL_VERSION    => '5.20.1',
    PREREQ_PM           => {
        'Text::Markdown'    => '1.000031',
        'Mojolicious'       => '8.12',
        'YAML::XS'          => '0.76',
    },
    TEST_REQUIRES => {
        'Test::Exception'   => '0.43',
    },
    META_MERGE          => {resources => {
        bugtracker => 'https://github.com/memowe/dirdown/issues',
        repository => 'https://github.com/memowe/dirdown',
    }},
    test                => {TESTS => 't/*.t t/*/*.t'},
);
