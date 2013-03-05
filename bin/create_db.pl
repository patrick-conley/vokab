#!/usr/bin/perl

use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;
use 5.012;

use Cwd;

my $Source_Path;
BEGIN { $Source_Path = Cwd::abs_path(__FILE__) =~ s!/[^/]*/[^/]*$!!r; }

use lib "$Source_Path/lib";
use Vokab::DB;

if ( @ARGV < 1 || $ARGV[0] =~ /--help|-h/ )
{
   say 'Usage: create_db.pl $dbname';
   exit(1);
}

my $db = Vokab::DB->new( dbname => "$Source_Path/data/$ARGV[0]" );
$db->create_db();
