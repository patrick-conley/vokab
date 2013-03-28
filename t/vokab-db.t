use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;
use 5.012;

use Test::Most tests => 47;
use File::Temp;
use Carp;
use Data::Dumper;

BEGIN {
   bail_on_fail();
   use_ok( "Vokab::DB" );
   restore_fail();
}

my %data = (
   chapter => { write => { chapter => 2, title => 'chapter' },
                read => { chapter => 2, title => 'chapter' } },
   section => { write => { en => 'en', de => 'de' },
                read => { en => 'en', de => 'de' } },
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
   my @ancestors = $class =~ /::(\w*)::/g;
   shift @ancestors;

   my ( $db, $id );

   # Create a new database
   lives_ok {
      $db = Vokab::DB->new( dbname => (File::Temp::tempfile())[1],
         error_handler => \&handle_exceptions_fallback );
      $db->create_db;

      # Write data necessary to satisfy foreign key constraints
      $db->dbh->do( "insert into Types(name, tablename, class) values "
         . "('foo_item', 'foo_items', 'Vokab::Item::Foo'), "
         . "('foo_word', 'foo_words', 'Vokab::Item::Word::Foo');" );
      $db->write_chapter( %{$data{chapter}->{write}} );
      $db->write_section( %{$data{section}->{write}} );

      # Write the Vokab::Item data
      $id = $db->write_item( %{$data{item}->{write}}, class => $class );

      # Write Vokab::Item::*:: data
      foreach my $ancestor ( @ancestors )
      {
         my $writer = "write_" . lc $ancestor;
         $db->$writer( id => $id, %{$data{lc $ancestor}->{write}} );
      }
   } "Setup works";

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

die_on_fail();
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

# read_section [3] {{{2
$db->dbh->do(
   "INSERT INTO Sections VALUES ( 'foo', 'bar' ), ( 1, 'foo' );"
);
is_deeply( $db->read_section( 'baz' ), undef,
   "->read_section works (undefined section)" );
is_deeply( $db->read_section( 'foo' ), { en => 'foo', de => 'bar' },
   "->read_section works (defined section)" );
is_deeply( $db->read_section( 1 ), { en => 1, de => 'foo' },
   "->read_section works (numeric section)" );
# }}}2
restore_fail();

# Test writing functions {{{1

# write_chapter [4] {{{2
{
   $db = Vokab::DB->new( dbname => (File::Temp::tempfile())[1],
      error_handler => \&handle_exceptions_fallback );
   $db->create_db;

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
      "->write_chapter works" );
}

# write_section [4] {{{2
{
   $db = Vokab::DB->new( dbname => (File::Temp::tempfile())[1],
      error_handler => \&handle_exceptions_fallback );
   $db->create_db;

   # good section succeeds
   lives_ok { $db->write_section( %{$data{section}->{write}} ) }
      "->write_section runs";
   is_deeply( $db->dbh->selectrow_hashref(
         "select * from Sections where en = $data{section}->{read}->{en}" ),
      $data{section}->{write},
      "->write_section works" );

   # bad section fails cleanly
   lives_ok { $db->write_section( en => $data{section}->{write}->{en},
                                  de => "duplicate" ) }
      "->write_section exits cleanly on duplicate keys";
   is_deeply( $db->dbh->selectrow_hashref(
         "select * from Sections where en = $data{section}->{read}->{en}" ),
      $data{section}->{write},
      "->write_section doesn't clobber on duplicate keys" );
}

# write_item & write_word [3] {{{2
# This can't be efficiently tested by test_class as Vokab::Item::Word is not a
# valid classname
{
   my ( $id, $class );

   # Create a new database
   $db = Vokab::DB->new( dbname => (File::Temp::tempfile())[1],
      error_handler => \&handle_exceptions_fallback );
   $db->create_db;
   $db->write_chapter( %{$data{chapter}->{write}} );
   $db->write_section( %{$data{section}->{write}} );

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
      $db->write_word( id => $id, en => $data{word}->{write}->{en}, de => 'differs' ),
      }
      "->write_word allows several words to share 'en'";

   restore_fail();

   # duplicate word fails
   throws_ok { $db->write_word( id => $id, %{$data{word}->{write}} ) }
      qr/is not unique/,
      "->write_word fails on items with identical en/de pairs";

   # writing word for a non-Word item fails
   my $defined_classes =
      $db->dbh->selectall_arrayref( "SELECT class FROM Types" );
   $class = "Vokab::Item::Foo";

   $db->dbh->do( "insert into Types(name, tablename, class) values "
      . "('foo_item', 'foo_items', 'Vokab::Item::Foo'), "
      . "('foo_word', 'foo_words', 'Vokab::Item::Word::Foo');" );

   throws_ok { 
      $id = $db->write_item( %{$data{item}->{write}}, class => $class ); 
      $db->write_word( id => $id, %{$data{word}->{write}} )
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
      $db->write_word( id => $id, en => $data{word}->{write}->{en}, de => "differs" );
      $db->write_noun( id => $id, %{$data{noun}->{write}} )
   }
      qr/Ambigious noun definition: \("en", "gender"\) pair is not unique/,
      "->write_noun fails if two items have the same 'en' and 'gender'";

   # similar item fails unless display_gender is true
   TODO: {
      local $TODO = "display_gender should be set implicitly";
      dies_ok { $db->write_noun( id => $id, gender => 'f', 
                                  display_gender => 0 ) }
         "->write_noun fails identical nouns with the same gender";
   }

   # slightly different item succeeds
   lives_ok { $db->write_noun( id => $id, gender => 'f', 
                               display_gender => 1 ) }
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
      qr/Ambigious verb definition: "en" is not unique/,
      "->write_verb fails if two items have the same 'en'";
}

# write_generic [4] {{{2
{
   my $db = test_class( "Generic" );
   my $id;

   # similar generics fail
   throws_ok {
      $id = $db->write_item( %{$data{item}->{write}}, class => "Vokab::Item::Word::Generic" );
      $db->write_word( id => $id, en => $data{word}->{write}->{en}, de => "differs" );
      $db->write_generic( id => $id, %{$data{generic}->{write}} )
      }
      qr/Ambiguous generic definition: "en" is not unique/,
      "->write_generic fails if two items have the same 'en'";
}

# }}}2

# }}}1
