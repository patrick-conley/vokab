use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;
use 5.012;

use Test::Most tests => 49;
use File::Temp;
use Carp;

BEGIN {
   bail_on_fail();
   use_ok( "Vokab::DB" );
   restore_fail();
}

my %data = (
   chapter => { write => { chapter => 2, title => 'chapter' },
                read => { chapter => 2, title => 'chapter' } },
   section => { write => { en => 'en', de => 'de', chapter => 2 },
                read => { en => 'en', de => 'de', chapter => 2 } },
   item =>    { write => { note => 'note', tests => -1, success => 0,
                           score => 0.95, chapter => 2, section => 'en' },
                read => { note => 'note', tests => -1, success => 0,
                          score => 0.95, chapter => 2, section => 'en' } },
   word =>    { write => { en => 'en', de => 'de' },
                read => { en => 'en', de => 'de' } },
   noun =>    { write => { gender => 'm', display_gender => 1 },
                read => { gender => 'm', display_gender => 1 } },
   verb =>    { write => { ich => 'bin', du => 'bist', er => 'ist',
                           wir => 'sind', ihr => 'sein', sie => 'sind',
                           Sie => 'sind' },
                read => { s1 => 'bin', s2 => 'bist', s3 => 'ist', p1 => 'sind',
                          p2 => 'sein', p3 => 'sind', f2 => 'sind' }, },
   generic => { write => { alternate => "/foo/" },
                read => { alternate => "/foo/" } },
);

my $db;

# Handler:  handle_exceptions_fallback() {{{1
# Purpose:  A fallback from the default, GUI exception handler.
sub handle_exceptions_fallback
{
   confess shift;
}

# Function: $db = new_db( chapter => \%ch, section => \%sec ) {{{1
# Purpose:  Create a new DB and add a chapter and section
sub new_db
{
   my %data = @ARG;

   my $db = Vokab::DB->new( dbname => (File::Temp::tempfile())[1],
      error_handler => \&handle_exceptions_fallback );
   $db->create_db;

   $db->write_chapter( %{$data{chapter}->{write}} );
   $db->write_section( %{$data{section}->{write}} );
   
   return $db;
}

# Function: $db = test_class( $classname ) {{{1
# Purpose:  Test the main behaviour of a class: that a certain set of
#           attributes succeeds, that an incorrect class fails
# Input:    An unqualified classname (eg "Noun", not "Vokab::Item::Word::Noun")
sub test_class
{
   my $classname = shift;

   my ( $table, $class ) = $db->dbh->selectrow_array(
      "SELECT tablename, class FROM Types WHERE name = '$classname'" );

   # Get ancestors of the class
   my @ancestors = $class =~ /:(\w+):/g;
   shift @ancestors;

   my $id;

   # Write ancestor data
   lives_ok {
      # Write the Vokab::Item data
      $id = $db->write_item( %{$data{item}->{write}}, class => $class );

      # Write Vokab::Item::*:: data
      if ( $ancestors[0] eq "Word" )
      {
         $db->write_word( id => $id, en => $data{word}->{write}->{en}, de => "$id" );
      }
   } " $classname setup works";

   my $writer = "write_" . lc $classname;

   # A good item succeeds
   lives_ok { $db->$writer( id => $id, %{$data{lc $classname}->{write}} ) }
      "->$writer runs";

   is_deeply(
      $db->dbh->selectrow_hashref(
         "select * from $table where id = $id" ),
      { id => $id, %{$data{lc $classname}->{read}} },
      "->$writer works" );

   # A good item with an incorrect class fails
   my $fake_class = $class =~ s/\w*$/Foo/r;

   throws_ok {
      $id = $db->write_item( %{$data{item}->{write}}, class => $fake_class );
      $db->$writer( id => $id, %{$data{lc $classname}->{write}} )
      }
      qr/Useless attempt to write $classname data for a $fake_class object/,
      "->$writer fails when its Vokab::Item parent is not a $classname";

   return $db;
}

# }}}1

# Test basic functions [5] {{{1
lives_ok { 
   $db = Vokab::DB->new( dbname => '/no/such/path', error_handler =>
      \&handle_exceptions_fallback );
} "Can't connect to a nonexistant database";

throws_ok { $db->create_db } qr/unable to open database file/,
   "Fails on inaccessible database";

bail_on_fail();
ok( 
   $db = Vokab::DB->new( dbname => (File::Temp::tempfile())[1], 
      error_handler => \&handle_exceptions_fallback ),
   "Vokab::DB->new()"
);
restore_fail();

die_on_fail();
isa_ok( $db, "Vokab::DB", "Vokab::DB->new returns a Vokab::DB" );
restore_fail();

ok( $db->create_db, "Create a DB" );
throws_ok { $db->create_db } qr/table \w* already exists/,
   "Don't clobber the DB";
   
# Test reading functions [9] {{{1

# readall_item_types [3] {{{2
is_deeply( $db->readall_item_types(), [
      [ 'Noun', 'Vokab::Item::Word::Noun' ],
      [ 'Verb', 'Vokab::Item::Word::Verb' ],
      [ 'Generic', 'Vokab::Item::Word::Generic' ],
   ],
   "->readall_item_types works" );

# read_chapter_title [3] {{{2
$db->dbh->do(
   "INSERT INTO Chapters VALUES( 0, 'Introduction'), ( 1, 'Einführung' );"
);

is( $db->read_chapter_title( 2 ), undef,
   "->read_chapter_title works (undefined chapter)" );
is( $db->read_chapter_title( 0 ), "Introduction", 
   "->read_chapter_title works (defined chapter)" );
is( $db->read_chapter_title( 1 ), "Einführung",
   "->read_chapter_title works (defined chapter with Unicode)" );

# read_section [4] {{{2
$db->dbh->do(
   "INSERT INTO Sections( chapter, en, de ) "
   . "VALUES ( 1, 'foo', 'bar' ), ( 0, 1, 'foo');"
);

is_deeply( $db->read_section( chapter => 1, en => 'baz' ), undef,
   "->read_section returns nothing (undefined section)" );
is_deeply( $db->read_section( chapter => 2, en => 'foo' ), undef,
   "->read_section returns nothing (defined section, wrong chapter)" );
is_deeply( $db->read_section( chapter => 1, en => 'foo' ),
   { en => 'foo', de => 'bar', chapter => 1 },
   "->read_section works (defined section)" );
is_deeply( $db->read_section( chapter => 0, en => 1 ),
   { en => 1, de => 'foo', chapter => 0 },
   "->read_section works (numeric section)" );
# }}}2

# Test writing functions {{{1
$db = Vokab::DB->new( dbname => (File::Temp::tempfile())[1],
   error_handler => \&handle_exceptions_fallback );
$db->create_db;

$db->dbh->do( "insert into Types(name, tablename, class) values "
   . "('foo_item', 'foo_items', 'Vokab::Item::Foo'), "
   . "('foo_word', 'foo_words', 'Vokab::Item::Word::Foo');" );

# write_chapter [4] {{{2
{
   # good chapter succeeds
   lives_ok { $db->write_chapter( %{$data{chapter}->{write}} ) }
      "->write_chapter runs";

   is_deeply(
      $db->dbh->selectrow_hashref(
         "select * from Chapters where chapter = $data{chapter}->{read}->{chapter}" ),
      $data{chapter}->{write},
      "->write_chapter works" );

   # bad chapter fails cleanly
   lives_ok { $db->write_chapter( chapter => $data{chapter}->{write}->{chapter}, 
                                  title => "duplicate" ) }
      "->write_chapter exits cleanly on duplicate keys";
   is_deeply(
      $db->dbh->selectrow_hashref(
         "select * from Chapters where chapter = $data{chapter}->{read}->{chapter}" ),
      $data{chapter}->{write},
      "->write_chapter works on duplicate keys" );
}

# write_section [4] {{{2
{

   # good section succeeds
   lives_ok { $db->write_section( %{$data{section}->{write}} ) }
      "->write_section runs";
   is_deeply( $db->dbh->selectrow_hashref(
         "SELECT * FROM Sections"
         . " WHERE en = '$data{section}->{read}->{en}'"
         . " AND chapter = '$data{section}->{read}->{chapter}'" ),
      $data{section}->{write},
      "->write_section works" );

   # bad section fails cleanly
   lives_ok { $db->write_section( en => $data{section}->{write}->{en},
                                  chapter => $data{section}->{write}->{chapter},
                                  de => "duplicate" ) }
      "->write_section exits cleanly on duplicate keys";
   is_deeply( $db->dbh->selectrow_hashref(
         "SELECT * FROM Sections"
         . " WHERE en = '$data{section}->{read}->{en}'"
         . " AND chapter = '$data{section}->{read}->{chapter}'" ),
      $data{section}->{write},
      "->write_section doesn't clobber on duplicate keys" );

   # similar section in a different chapter succeeds
   lives_ok {
      $db->write_chapter( chapter => 3, title => 'foo' );
      $db->write_section( chapter => 3,
                          en => $data{section}->{write}->{en},
                          de => $data{section}->{write}->{de} )
      }
      "->write_section runs with similar section in different chapter";
   is_deeply( $db->dbh->selectrow_hashref(
         "SELECT * FROM Sections"
         . " WHERE en = '$data{section}->{read}->{en}'"
         . " AND chapter = 3" ),
      { chapter => 3,
         en => $data{section}->{read}->{en},
         de => $data{section}->{read}->{de} },
      "->write_section works with similar section in different chapter" );
}

# write_item & write_word [3] {{{2
# This can't be efficiently tested by test_class as Vokab::Item::Word is not a
# valid classname
{
   my ( $id, $class );
   $class = "Vokab::Item::Word::Noun";

   die_on_fail();

   # good item succeeds
   lives_ok { $id = $db->write_item( %{$data{item}->{write}}, class => $class) }
      "->write_item runs";
   is_deeply(
      $db->dbh->selectrow_hashref( "SELECT * FROM Items where id = $id" ),
      { id => $id, %{$data{item}->{read}}, class => $class },
      "->write_item works" );

   # duplicate item succeeds
   lives_ok { $id = $db->write_item( %{$data{item}->{write}}, class => $class) }
      "->write_item allows identical items";

   # good word succeeds
   lives_ok { $db->write_word( id => $id, %{$data{word}->{write}} ) }
      "->write_word runs";
   is_deeply(
      $db->dbh->selectrow_hashref( "SELECT * FROM Words WHERE id = $id" ),
      { id => $id, %{$data{word}->{read}} },
      "->write_word works" );

   # slightly different word succeeds
   lives_ok {
      $id = $db->write_item( %{$data{item}->{write}}, class => $class );
      $db->write_word( id => $id, en => $data{word}->{write}->{en}, de => 'share en' ),
      }
      "->write_word allows several words to share 'en'";

   restore_fail();

   # duplicate word fails
   throws_ok { 
      $id = $db->write_item( %{$data{item}->{write}}, class => $class );
      $db->write_word( id => $id, %{$data{word}->{write}} )
      }
      qr/columns? [, \w]* (is|are) not unique/,
      "->write_word fails on items with identical en/de pairs";

   # writing word for a non-Word item fails
   my $defined_classes =
      $db->dbh->selectall_arrayref( "SELECT class FROM Types" );
   $class = "Vokab::Item::Foo";

   throws_ok { 
      $id = $db->write_item( %{$data{item}->{write}}, class => $class ); 
      $db->write_word( id => $id,
         en => $data{word}->{write}->{en}, de => 'wrong class' )
      }
      qr/Useless attempt to write Word data for a $class object/,
      "->write_word fails when its Vokab::Item parent is not a word";
}

# write_noun [5] {{{2
{
   my $db = test_class( "Noun" );
   my $id;

   # too-similar item fails
   throws_ok {
      $id = $db->write_item( %{$data{item}->{write}}, class => "Vokab::Item::Word::Noun" );
      $db->write_word( id => $id, en => $data{word}->{write}->{en}, de => "same gender" );
      $db->write_noun( id => $id, %{$data{noun}->{write}} )
   }
      qr/Ambiguous Noun definition/,
      "->write_noun fails if two items have the same 'en' and 'gender'";

   # slightly different item succeeds
   lives_ok {
      $id = $db->write_item( %{$data{item}->{write}}, class => "Vokab::Item::Word::Noun" );
      $db->write_word( id => $id, en => $data{word}->{write}->{en}, de => "gender differs" );
      $db->write_noun( id => $id, gender => 'f', display_gender => 1 )
      }
      "->write_noun allows two nouns only differing in gender";
}

# write_verb [4] {{{2
{
   my $db = test_class( "Verb" );
   my $id;

   # similar verbs fail
   throws_ok {
      $id = $db->write_item( %{$data{item}->{write}}, class => "Vokab::Item::Word::Verb" );
      $db->write_word( id => $id, en => $data{word}->{write}->{en}, de => "differs" );
      $db->write_verb( id => $id,
         ich => 'habe', du => 'hast', er => 'hat', Sie => 'haben',
         wir => 'haben', ihr => 'hat', sie => 'haben' ) }
      qr/Ambiguous Verb definition/,
      "->write_verb fails if two items have the same 'en'";
}

# write_generic [4] {{{2
{
   my $db = test_class( "Generic" );
   my $id;

   # similar generics fail
   throws_ok {
      $id = $db->write_item( %{$data{item}->{write}}, class => "Vokab::Item::Word::Generic" );
      $db->write_word( id => $id, en => $data{word}->{write}->{en}, de => "dup generic" );
      $db->write_generic( id => $id, %{$data{generic}->{write}} )
      }
      qr/Ambiguous Generic definition/,
      "->write_generic fails if two items have the same 'en'";
}

# }}}2

# }}}1
