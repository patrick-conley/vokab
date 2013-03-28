package Vokab::DB;

use strict;
use warnings;
use English qw/ -no-match-vars /;
use utf8;
use 5.012;

# A class for DB access

use DBI;
use Log::Handler 'vokab';
use Gtk2;
use TryCatch;
use Data::Dumper;

use Moose;
use MooseX::FollowPBP;
use namespace::autoclean;

# Attributes {{{1
has 'dbname' => ( is => 'ro',
                  required => 1,
                );

has 'error_handler' => ( is => 'ro',
                         default => sub { \&handle_db_exceptions },
                       );

has 'dbh' => ( is => 'ro',
               builder => '_init_dbh',
               isa => 'DBI::db',
               reader => 'dbh',
               lazy => 1, # has to be lazy, since it reads other attributes
               init_arg => undef,
             );

has 'log' => ( is => 'ro', # Log::Handler object for debugging output
               default => sub { return Log::Handler->get_logger("vokab"); },
               reader => 'log',   # override Moose::FollowPBP
               lazy => 1,         # don't set it until used
               init_arg => undef, # don't allow this to be set with new()
               isa => 'Log::Handler'
             );

# }}}1

# Method:   _init_dbh {{{1
# Purpose:  Initialize the 'dbh' attribute
sub _init_dbh
{
   my $self = shift;
   
   my $dbh = DBI->connect( "dbi:SQLite:dbname=" . $self->get_dbname(),
      "", "", {
 #          RaiseError => 1,
         HandleError => $self->get_error_handler,
         AutoCommit => 1,
      } ) or $self->log->alert( $DBI::errstr );

   $dbh->{sqlite_unicode} = 1;
	$dbh->do( "PRAGMA foreign_keys = ON" );
   $dbh->{sqlite_see_if_its_a_number} = 1;

	return $dbh;
}

# Handler:  handle_db_exceptions() {{{1
# Purpose:  A common error-handler for all DB-interacting GUIs. Display an
#           error message and quit.
# Input:    (string) error message
#           (object) DB handle
sub handle_db_exceptions
{
   my $msg = shift;

   my $window = Gtk2::MessageDialog->new(
      undef, "destroy_with_parent", "GTK_MESSAGE_ERROR",
      "close", "The Vokab DB threw exception:\n %s", $msg );
   $window->run();
   $window->destroy();

   # The error-handler is not called as a method of Vokab::DB: it doesn't
   # inherit the object's logger
   # Note that alert will die, passing the exception up to the Glib exception
   # handler, if the mainloop is running
   my $Log = Log::Handler->get_logger( 'vokab' );
   $Log->alert( "DB threw exception: $msg" );
}

# Method:   create_db() {{{1
# Purpose:  Create a new database all appropriate tables
# Input:    N/A
# Output:   N/A
sub create_db
{
   my $self = shift;

   $self->log->notice( "Initializing a new database" );

   # Chapters {{{2
   $self->dbh->do( <<EOT
      CREATE TABLE Chapters(
         chapter INTEGER PRIMARY KEY,
         title TEXT NOT NULL
      );
EOT
   );

   # Sections {{{2
   $self->dbh->do( <<EOT
      CREATE TABLE Sections(
         en TEXT PRIMARY KEY,
         de TEXT UNIQUE NOT NULL
      );
EOT
   );

	# Item types {{{2
	$self->dbh->do( <<EOT
		CREATE TABLE Types(
			name TEXT NOT NULL,
         tablename TEXT NOT NULL,
			class TEXT PRIMARY KEY
		);
EOT
	);

   # Items {{{2
   $self->dbh->do( <<EOT
      CREATE TABLE Items(
         id INTEGER PRIMARY KEY,
         chapter INTEGER,
         section INTEGER,
         class INTEGER NOT NULL,
         tests INTEGER,
         success INTEGER,
         score REAL NOT NULL,
         note TEXT,
         FOREIGN KEY(chapter) REFERENCES Chapters(chapter),
         FOREIGN KEY(section) REFERENCES Sections(en),
         FOREIGN KEY(class) REFERENCES Types(class)
      );
EOT
   );

   # Word items {{{2
   $self->dbh->do( <<EOT
      CREATE TABLE Words(
         id INTEGER,
         en TEXT NOT NULL,
         de TEXT NOT NULL,
         FOREIGN KEY(id) REFERENCES Items(id)
      );
EOT
   );

   # Noun words {{{2
   $self->dbh->do( <<EOT
      CREATE TABLE Nouns(
         id INTEGER,
         gender TEXT,
         display_gender INTEGER,
         FOREIGN KEY(id) REFERENCES Items(id)
      );
EOT
   );
	$self->dbh->do( "INSERT INTO Types VALUES('Noun', 'Nouns', 'Vokab::Item::Word::Noun')" );

   # Verb words {{{2
   $self->dbh->do( <<EOT
      CREATE TABLE Verbs(
         id INTEGER,
         s1 TEXT, s2 TEXT, s3 TEXT,
         p1 TEXT, p2 TEXT, p3 TEXT,
         f2 TEXT,
         FOREIGN KEY(id) REFERENCES Items(id)
      );
EOT
   );
	$self->dbh->do( "INSERT INTO Types VALUES('Verb', 'Verbs', 'Vokab::Item::Word::Verb')" );

   # Generic words {{{2
   $self->dbh->do( <<EOT
      CREATE TABLE Generics(
         id INTEGER,
         alternate TEXT,
         FOREIGN KEY(id) REFERENCES Items(id)
      );
EOT
   );
	$self->dbh->do( "INSERT INTO Types VALUES('Generic', 'Generics', 'Vokab::Item::Word::Generic')" );

   # }}}2
}

# }}}1

# Method:   readall_item_types {{{1
sub readall_item_types
{
   my $self = shift;
   return $self->dbh->selectall_arrayref( "SELECT name, class FROM Types;" );
}

# Method:   read_section {{{1
sub read_section
{
   my $self = shift;
   my ( $en ) = Params::Validate::validate_pos( @_,
      { type => Params::Validate::SCALAR }
   );

   my $sth = $self->dbh->prepare(
      "SELECT en, de FROM Sections WHERE en = ?"
   );
   $sth->execute( $en );
   my $val = $sth->fetchrow_hashref;

   return $val;
}

# Method:   read_chapter_title {{{1
sub read_chapter_title
{
   my $self = shift;
   my ( $ch ) = Params::Validate::validate_pos( @_,
      { type => Params::Validate::SCALAR, regex => qr/^\d+$/ }
   );

   my $sth = $self->dbh->prepare(
      "SELECT title FROM Chapters WHERE Chapter = ?"
   );
   $sth->execute( $ch );
   my $val = $sth->fetchrow_array;

   return $val;
}

# }}}1

# FIXME: writing methods MUST use transactions and roll back on error
# disable autocommit and start/commit in Vokab::Add
# Method:   write_chapter( chapter => $$, title => $$ ) {{{1
# Purpose:  Add a new chapter to the DB
sub write_chapter
{
   my $self = shift;
   my %args = Params::Validate::validate( @_, {
         chapter => { type => Params::Validate::SCALAR, regex => qr/^\d+$/ },
         title => { type => Params::Validate::SCALAR },
      } );

   $self->log->info( "Writing chapter ".
      Data::Dumper::Dumper( %args )
      . " to the DB" );

   my $sth = $self->dbh->prepare(
      "INSERT INTO Chapters ( chapter, title ) VALUES ( ?, ? );"
   );

   try
   {
      $sth->execute( $args{chapter}, $args{title} );
   }
   catch ( $e =~ /PRIMARY KEY must be unique/ )
   {
      $self->log->debug( "Chapter $args{chapter} already exists in the DB."
         . " Continuing" );
   }
}

# Method:   write_section( en => $$, de => $$ ) {{{1
# Purpose:  Add a new section to the DB
sub write_section
{
   my $self = shift;
   my %args = Params::Validate::validate( @_, {
         en => { type => Params::Validate::SCALAR },
         de => { type => Params::Validate::SCALAR },
      } );

   $self->log->info( "Writing section ".
      Data::Dumper::Dumper( %args )
      . " to the DB" );

   my $sth = $self->dbh->prepare(
      "INSERT INTO Sections ( en, de ) VALUES ( ?, ? );"
   );

   try
   {
      $sth->execute( $args{en}, $args{de} );
   }
   catch ( $e =~ /PRIMARY KEY must be unique/ )
   {
      $self->log->debug( "Section $args{en} already exists in the DB."
         . " Continuing" );
   }
}

# Method:   id = write_item( class => $$, chapter => $$, section => $$, {{{1 
#                       note => $$, tests => $$, success => $$, score => $$ ) 
# Purpose:  Add a new item to the DB
sub write_item
{
   my $self = shift;
   my %args = Params::Validate::validate( @_, {
         class => { type => Params::Validate::SCALAR },
         chapter => { type => Params::Validate::SCALAR },
         section => { type => Params::Validate::SCALAR },
         note => { type => Params::Validate::SCALAR },
         tests => { type => Params::Validate::SCALAR },
         success => { type => Params::Validate::SCALAR },
         score => { type => Params::Validate::SCALAR },
      } );

   $self->log->info( "Writing item ".
      Data::Dumper::Dumper( %args )
      . " to the DB" );

   my $sth = $self->dbh->prepare(
      "INSERT INTO Items ( class, chapter, section, note, tests, success, score )"
      . " VALUES ( ?, ?, ?, ?, ?, ?, ? );"
   );

   $sth->execute( $args{class}, $args{chapter}, $args{section},
      $args{note}, $args{tests}, $args{success}, $args{score}
   );
   
   my $id = $self->dbh->sqlite_last_insert_rowid();
   $self->log->debug( "Wrote item to table row $id" );
   return $id

}

# Method:   write_word( id => $$, en => $$, de => $$ ) {{{1
# Purpose:  Add a new word to the DB
sub write_word
{
   my $self = shift;
   my %args = Params::Validate::validate( @_, {
         id => { type => Params::Validate::SCALAR },
         en => { type => Params::Validate::SCALAR },
         de => { type => Params::Validate::SCALAR },
      } );

   $self->log->info( "Writing word ".
      Data::Dumper::Dumper( %args )
      . " to the DB" );

   my $sth = $self->dbh->prepare(
      "INSERT INTO Words ( id, en, de ) VALUES ( ?, ?, ? );"
   );

   $sth->execute( $args{id}, $args{en}, $args{de} );
}

# Method:   write_noun( id => $$, gender => $$, display_gender => $$ ) {{{1
# Purpose:  Add a new noun to the DB
sub write_noun
{
   my $self = shift;
   my %args = Params::Validate::validate( @_, {
         id => { type => Params::Validate::SCALAR },
         gender => { type => Params::Validate::SCALAR },
         display_gender => { type => Params::Validate::SCALAR },
      } );

   $self->log->info( "Writing noun ".
      Data::Dumper::Dumper( %args )
      . " to the DB" );

   my $sth = $self->dbh->prepare(
      "INSERT INTO Nouns ( id, gender, display_gender ) VALUES ( ?, ?, ? );"
   );

   $sth->execute( $args{id}, $args{gender}, $args{display_gender} );
}

# Method:   write_verb( id => $$, conjugation ) {{{1
# Purpose:  Add a new verb to the DB
sub write_verb
{
   my $self = shift;
   my %args = Params::Validate::validate( @_, {
         id => { type => Params::Validate::SCALAR },
         ich => { type => Params::Validate::SCALAR },
         du => { type => Params::Validate::SCALAR },
         er => { type => Params::Validate::SCALAR },
         Sie => { type => Params::Validate::SCALAR },
         wir => { type => Params::Validate::SCALAR },
         ihr => { type => Params::Validate::SCALAR },
         sie => { type => Params::Validate::SCALAR },
      } );

   $self->log->info( "Writing verb ".
      Data::Dumper::Dumper( %args )
      . " to the DB" );

   my $sth = $self->dbh->prepare(
      "INSERT INTO Verbs ( id, s1, s2, s3, p1, p2, p3, f2 ) "
      . "VALUES ( ?, ?, ?, ?, ?, ?, ?, ? );"
   );

   $sth->execute( $args{id},
      $args{ich}, $args{du}, $args{er},
      $args{wir}, $args{ihr}, $args{sie}, $args{Sie},
   );
}

# Method:   write_generic( id => $$, alternate => $$ ) {{{1
# Purpose:  Add a new generic to the DB
sub write_generic
{
   my $self = shift;
   my %args = Params::Validate::validate( @_, {
         id => { type => Params::Validate::SCALAR },
         alternate => { type => Params::Validate::SCALAR },
      } );

   $self->log->info( "Writing generic word ".
      Data::Dumper::Dumper( %args )
      . " to the DB" );

   my $sth = $self->dbh->prepare(
      "INSERT INTO Generics ( id, alternate ) VALUES ( ?, ? );"
   );

   $sth->execute( $args{id}, $args{alternate} );
}

# }}}1

1;
