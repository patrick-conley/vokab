use strict;
use warnings;
use English;
use utf8;

use Test::More tests => 6;
use Test::Exception;
use Test::Deep;

use File::Temp;
use DBI;

my $Source_Path;
BEGIN { $Source_Path = Cwd::abs_path(__FILE__) =~ s!/[^/]*/[^/]*$!!r; }
use lib "$Source_Path/lib";

BEGIN { use_ok( "Vokab::DB" ); }

my $db;
my $dbname = File::Temp::tempdir() . "/vokab.db";
 # my $dbname = "test.db";

# Handler:  handle_exceptions_fallback() {{{1
# Purpose:  A fallback from the default, GUI exception handler.
sub handle_exceptions_fallback
{
   die shift;
}

# }}}1

# Test basic functions {{{1
$db = Vokab::DB->new( dbname => '/no/such/path', error_handler =>
   \&handle_exceptions_fallback );

throws_ok { $db->create_db } qr/unable to open database file/,
   "Fails on inaccessible database";

isa_ok(
   $db = Vokab::DB->new( dbname => $dbname, error_handler => \&handle_exceptions_fallback ),
   "Vokab::DB" );

ok( $db->create_db, "Create a DB" );
throws_ok { $db->create_db } qr/table \w* already exists/,
   "Don't clobber the DB";
   
# Test prepared statements {{{1
cmp_deeply( $db->readall_item_types(), [
      [ 'Noun', 'Vokab::Item::Word::Noun' ],
      [ 'Verb', 'Vokab::Item::Word::Verb' ],
      [ 'Generic', 'Vokab::Item::Word::Generic' ],
   ],
   "Method readall_item_types" );
