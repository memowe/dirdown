use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    VERSION             => '0.1',
    MIN_PERL_VERSION    => '5.20.1',
    PREREQ_PM           => {
        'Text::Markdown'    => '1.000031',
        'Mojolicious'       => '8.06',
        'YAML'              => '1.27',
    },
    test                => {TESTS => 't/*.t t/*/*.t'},
);
