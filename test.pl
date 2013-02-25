#!/usr/bin/perl

use strict;
use warnings;
use English;
use utf8;
use 5.012;

use TAP::Harness;

my @tests = (
   'vokab-types',
   'db',
   'vokab-items',
);

@tests = map { "t/$ARG.t" } @tests;

my $harness = TAP::Harness->new( {
      verbosity => 0,
      lib => [ 'lib', 't/lib' ],
   } );

$harness->runtests( @tests );
