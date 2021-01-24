#!/usr/bin/perl
use Test::More;
use lib 'lib';
use Module::Pluggable search_path => ['App::TimeTracker'];

require_ok($_) for sort __PACKAGE__->plugins;

done_testing();
