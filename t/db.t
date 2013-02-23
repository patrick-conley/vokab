use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;

use Test::Most tests => 7;
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
   
# Test prepared statements {{{1
cmp_deeply( $db->readall_item_types(), [
      [ 'Noun', 'Vokab::Item::Word::Noun' ],
      [ 'Verb', 'Vokab::Item::Word::Verb' ],
      [ 'Generic', 'Vokab::Item::Word::Generic' ],
   ],
   "Method readall_item_types" );
