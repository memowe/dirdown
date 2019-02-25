#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;

local $ENV{MOJO_LOG_LEVEL} = 'error';
local $ENV{DIRDOWN_DEBUGROUTE} = '/debug';
my $t = Test::Mojo->new('Dirdown');

# TODO
$t->get_ok('/debug')->status_is(200);

done_testing;
