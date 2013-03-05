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

	return $dbh;
}

# Method:   destructor {{{1
sub DEMOLISH
{
   my $self = shift;

   $self->dbh->disconnect() if ( defined $self->dbh );
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
         section_id INTEGER PRIMARY KEY,
         section_en TEXT NOT NULL,
         section_de TEXT NOT NULL
      );
EOT
   );

	# Item types {{{2
	$self->dbh->do( <<EOT
		CREATE TABLE Types(
			name TEXT PRIMARY KEY,
			class TEXT NOT NULL
		);
EOT
	);

   # Items {{{2
   $self->dbh->do( <<EOT
      CREATE TABLE Items(
         id INTEGER PRIMARY KEY,
         chapter INTEGER,
         section_id INTEGER,
         type_id INTEGER NOT NULL,
         tests INTEGER DEFAULT 0,
         successes INTEGER DEFAULT 0,
         score REAL NOT NULL,
         note TEXT,
         FOREIGN KEY(chapter) REFERENCES Chapters(chapter),
         FOREIGN KEY(section_id) REFERENCES Sections(section_id),
         FOREIGN KEY(type_id) REFERENCES Types(type_id),
         CONSTRAINT valid_tests CHECK (tests>=0),
         CONSTRAINT valid_successes CHECK (successes>=0),
         CONSTRAINT valid_score CHECK (score>=0 AND score<=1)
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
	$self->dbh->do( "INSERT INTO Types VALUES('Noun','Vokab::Item::Word::Noun')" );

   # Verb words {{{2
   $self->dbh->do( <<EOT
      CREATE TABLE Verbs(
         id INTEGER,
         person TEXT,
         FOREIGN KEY(id) REFERENCES Items(id)
      );
EOT
   );
	$self->dbh->do( "INSERT INTO Types VALUES('Verb','Vokab::Item::Word::Verb')" );

   # Generic words {{{2
   $self->dbh->do( <<EOT
      CREATE TABLE Generic(
         id INTEGER,
         alternate TEXT,
         FOREIGN KEY(id) REFERENCES Items(id)
      );
EOT
   );
	$self->dbh->do( "INSERT INTO Types VALUES('Generic','Vokab::Item::Word::Generic')" );

   # }}}2
}

# }}}1

# Function: readall_item_types {{{1
sub readall_item_types
{
   my $self = shift;

   return $self->dbh->selectall_arrayref( "SELECT name, class FROM Types;" );
}

# Function: read_chapter_title {{{1
sub read_chapter_title
{
   my $self = shift;
   my ( $ch ) = Params::Validate::validate_pos( @_,
      { type => Params::Validate::SCALAR, regex => qr/^\d+$/ }
   );

   state $sth = $self->dbh->prepare(
      "SELECT title FROM Chapters WHERE Chapter = ?"
   );
   $sth->execute( $ch );

   return $sth->fetchall_arrayref->[0]->[0];
}

# }}}1

1;
