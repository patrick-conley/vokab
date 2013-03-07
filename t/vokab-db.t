use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;
use 5.012;

use Test::Most tests => 13;
use File::Temp;

BEGIN {
   bail_on_fail();
   use_ok( "Vokab::DB" );
   restore_fail();
}

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

bail_on_fail();
ok( 
   $db = Vokab::DB->new( dbname => $dbname, error_handler => \&handle_exceptions_fallback ),
   "Vokab::DB->new()"
);
restore_fail();

die_on_fail();
isa_ok( $db, "Vokab::DB", "Vokab::DB->new returns a Vokab::DB" );
restore_fail();

ok( $db->create_db, "Create a DB" );
throws_ok { $db->create_db } qr/table \w* already exists/,
   "Don't clobber the DB";
   
# Test prepared functions {{{1
is_deeply( $db->readall_item_types(), [
      [ 'Noun', 'Vokab::Item::Word::Noun' ],
      [ 'Verb', 'Vokab::Item::Word::Verb' ],
      [ 'Generic', 'Vokab::Item::Word::Generic' ],
   ],
   "->readall_item_types works" );

$db->dbh->do(
   "INSERT INTO Chapters VALUES( 0, 'Introduction'), ( 1, 'Einführung' );"
);

is( $db->read_chapter_title( 2 ), undef,
   "->read_chapter_title works (undefined chapter)" );
is( $db->read_chapter_title( 0 ), "Introduction", 
   "->read_chapter_title works (defined chapter)" );
is( $db->read_chapter_title( 1 ), "Einführung",
   "->read_chapter_title works (defined chapter with Unicode)" );

$db->dbh->do(
   "INSERT INTO Sections VALUES ( 'foo', 'bar' ), ( 1, 'foo' );"
);
is_deeply( $db->read_section( 'baz' ), undef,
   "->read_section works (undefined section)" );
is_deeply( $db->read_section( 'foo' ), { en => 'foo', de => 'bar' },
   "->read_section works (defined section)" );
is_deeply( $db->read_section( 1 ), { en => 1, de => 'foo' },
   "->read_section works (numeric section)" );
