package Vokab::Item;

use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;
use 5.012;

use Vokab::Types qw/Natural SemiNatural Real OptText Text Section /;

# A Vokab::Item is meant to be used for any testable object.

use Gtk2;
use Data::Dumper;
use Params::Validate;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::FollowPBP; # use get_, set_ accessors
use namespace::autoclean; # clean up Moose droppings

has( 'log' => (
      is => 'ro', # Log::Handler object for debugging output
      default => sub { return Log::Handler->get_logger("vokab"); },
      reader => 'log',   # override Moose::FollowPBP
      lazy => 1,         # don't set it until used
      init_arg => undef, # don't allow this to be set with new()
      isa => 'Log::Handler'
   )
);

has( 'db' => ( # Database handler
      is => 'ro',
      reader => 'db',
      isa => 'Vokab::DB'
   )
);

has( 'id' => ( is => 'rw', isa => Natural, init_arg => undef ) );
has( 'class' => ( is => 'rw', isa => 'ClassName', init_arg => undef ) );
has( 'tests' => ( is => 'rw', isa => SemiNatural, init_arg => undef ) );
has( 'success' => ( is => 'rw', isa => Natural, init_arg => undef ) );
has( 'score' => ( is => 'rw', isa => Real, init_arg => undef ) );

has( 'chapter' => ( is => 'rw', isa => Natural ) );
has( 'title' => ( is => 'rw', isa => Text, init_arg => undef ) );
has( 'note' => ( is => 'rw', isa => "Str", init_arg => undef ) );

has( 'section' => ( is => 'rw', isa => Section ) );

foreach my $field ( qw/ chapter title note / )
{
   has $field . "_field" => (
      is => 'ro',
      lazy => 1,
      builder => "_build_${field}_field",
      isa => "Gtk2::Widget",
      init_arg => undef,
   );
}

has "section_field" => (
   is => 'ro',
   lazy => 1,
   builder => "_build_section_field",
   isa => "HashRef[Gtk2::Widget]",
   init_arg => undef,
);

my $Initial_Score = 0.95;
my $Chapter_Modifier = -0.05;

# Method:   _build_chapter_field {{{1
# Purpose:  Builder for the chapter_field attribute
sub _build_chapter_field
{
   my $self = shift;

   my $entry = Gtk2::SpinButton->new_with_range( 0, 100, 1 );
   # Must connect the signal handler before setting the value
   $entry->signal_connect( changed => \&on_set_chapter_field, $self );
   $entry->set_value( $self->get_chapter ) if $self->get_chapter;
   $entry->set_activates_default(1);
   return $entry;
}

# Method:   _build_section_field {{{1
# Purpose:  Builder for the section_field attribute
sub _build_section_field
{
   my $self = shift;

   my $section = {};

   $section->{de} = Gtk2::Entry->new();
   if ( $self->get_section && $self->get_section->{de} )
   {
      $section->{de}->set_text( $self->get_section->{de} );
      $section->{de}->set_sensitive(0);
   }
   $section->{de}->set_activates_default(1);

   $section->{en} = Gtk2::Entry->new();
   $section->{en}->signal_connect( changed => \&on_set_section_field, $self );
   if ( $self->get_section && $self->get_section->{en} )
   {
      $section->{en}->set_text( $self->get_section->{en} );
   }
   $section->{en}->set_activates_default(1);

   return $section;
}

# Method:   _build_title_field {{{1
# Purpose:  Builder for the title_field attribute
sub _build_title_field
{
   my $self = shift;

   my $entry = Gtk2::Entry->new();
   $entry->set_activates_default(1);
   return $entry;
}

# Method:   _build_note_field {{{1
# Purpose:  Builder for the note_field attribute
sub _build_note_field
{
   my $self = shift;

   my $entry = Gtk2::Entry->new();
   $entry->set_activates_default(1);
   return $entry;
}

# Method:   display_all( box => $box ) {{{1
# Purpose:  Display entry fields for everything the item needs
# Input:    (Gtk::VBox) a box to hold everything
sub display_all
{
   # Get args
   my $self = shift;
   my %args = Params::Validate::validate( @_, {
         box => { isa => "Gtk2::Box" }
      }
   );

   # Table: Chapter & section
   my $table = Gtk2::HBox->new();
   {
      $args{box}->add( $table );
      $table->set_homogeneous( 0 );

      # Col: Label
      my $col = Gtk2::VBox->new();
      {
         $table->pack_start( $col, 0, 0, 0 );
         $col->set_homogeneous( 0 );
         $col->add( Gtk2::Label->new( "Chapter" ) );
         $col->add( Gtk2::Label->new( "Section" ) );
      }

      # Col: Entry fields
      $col = Gtk2::VBox->new();
      {
         $table->pack_start( $col, 0, 0, 0 );
         $col->set_homogeneous( 0 );

         # Must create a row to limit the width of the chapter entry field
         my $row = Gtk2::HBox->new();
         {
            $col->add( $row );
            $row->pack_start( $self->get_chapter_field, 0, 0, 0 );
            $row->add( $self->get_title_field );
         }

         $row = Gtk2::HBox->new();
         {
            $col->add( $row );
            $row->add( Gtk2::Label->new( "en" ) );
            $row->pack_start( $self->get_section_field->{en}, 0, 0, 0 );
            $row->pack_start( $self->get_section_field->{de}, 0, 0, 0 );
            $row->add( Gtk2::Label->new( "de" ) );
         }
      }

      $col = Gtk2::VBox->new();
      $table->add( $col );

   }

   # Divider to separate chapter/section from type-specific content
   $args{box}->pack_start( Gtk2::HSeparator->new(), 0, 0, 0 );

   # Add a descriptive label
   my $label = Gtk2::Label->new();
   $label->set_line_wrap(1);
   $label->set_alignment( 0.1, 0.5 );
   $args{box}->pack_start( $label, 0, 0, 0 );

   # children's table
   my $label_column;
   my $content_column;

   $table = Gtk2::HBox->new();
   {
      $args{box}->add( $table );
      $table->set_homogeneous( 0 );

      $label_column = Gtk2::VBox->new();
      $content_column = Gtk2::VBox->new();
      
      $table->pack_start( $label_column, 0, 0, 0 );
      $table->add( $content_column );
   }

   $label->set_text( join( "\n", inner() ) );

   # Add any comments about the item
   $label_column->add( Gtk2::Label->new( "Notes" ) );
   $content_column->add( $self->get_note_field );

}

# Method:   set_all() {{{1
# Purpose:  Set attributes according to the values in entry fields
sub set_all
{
   my $self = shift;

   $self->set_chapter( $self->get_chapter_field->get_value_as_int );
   $self->set_title( $self->get_title_field->get_text );
   $self->set_note( $self->get_note_field->get_text );

   if ( $self->get_section_field->{en}->get_text )
   {
      $self->set_section( {
            en => $self->get_section_field->{en}->get_text,
            de => $self->get_section_field->{de}->get_text,
         } );
   }

   $self->set_class( ref $self );
   $self->set_tests( -1 );
   $self->set_success( 0 );
   $self->set_score( $Initial_Score + $Chapter_Modifier * $self->get_chapter );

   inner();
}

# Method:   write_all() {{{1
# Purpose:  Call the DBH to write a new item
sub write_all
{
   my $self = shift;

   $self->db->write_chapter(
      chapter => $self->get_chapter,
      title => $self->get_title
   );

   $self->db->write_section(
      en => $self->get_section->{en},
      de => $self->get_section->{de}
   );

   my $id = $self->db->write_item( 
      class => $self->get_class,
      chapter => $self->get_chapter,
      section => $self->get_section->{en},
      note => $self->get_note,
      tests => $self->get_tests,
      success => $self->get_success,
      score => $self->get_score,
   );
   $self->set_id( $id );

   inner();
}

# Method:   dump() {{{1
# Purpose:  Return a hash of the object's writable attributes
sub dump
{
   my $self = shift;

   my %attrs;
   $attrs{chapter} = $self->get_chapter if $self->get_chapter;
   $attrs{title}   = $self->get_title   if $self->get_title;

   $attrs{section_en} = $self->get_section->{en} if $self->get_section->{en};
   $attrs{section_de} = $self->get_section->{de} if $self->get_section->{de};

   return (
      %attrs,
      inner()
   );
}

# Callback: on_set_chapter_field {{{1
# Purpose:  Called when the chapter # is changed. If the chapter exists in the
#           DB, the title is set accordingly and desensitized; if it doesn't,
#           the title is cleared and sensitized
# Input:    Calling widget (chapter_field) and self
sub on_set_chapter_field
{
   my ( $chapter, $self ) = @ARG;

   my $title = $self->db->read_chapter_title( $chapter->get_value_as_int );
   if ( $title )
   {
      $self->log->info( "Chapter title \"$title\" read from DB" );
      $self->get_title_field->set_text( $title );
      $self->get_title_field->set_sensitive(0);
   }
   elsif ( $self->get_title_field->get_text ) # only unset if it was set
   {
      $self->log->info( "Clearing chapter title" );
      $self->get_title_field->set_text( '' );
      $self->get_title_field->set_sensitive(1);
   }

   return 0;
}

# Callback: on_set_section_field {{{1
# Purpose:  Called when the section's English value is changed. If the section
#           exists in the DB, the Deutsch value is set and desensitized
# Input:    Calling widget (section field) and self
sub on_set_section_field
{
   my ( $en_field, $self ) = @ARG;

   my $section = $self->db->read_section( 
      chapter => $self->get_chapter_field->get_value_as_int,
      en => $en_field->get_text );
   if ( $section->{en} )
   {
      $self->log->info( "Section "
         . Data::Dumper::Dumper( $section )
         . " read from DB" );
      $self->get_section_field->{de}->set_text( $section->{de} );
      $self->get_section_field->{de}->set_sensitive(0);
   }
   elsif ( $self->get_section_field->{de}->get_text ) # only unset if it was set
   {
      $self->log->info( "Clearing section (De) (from "
         . $en_field->get_text
         . ")" );
      $self->get_section_field->{de}->set_text( '' );
      $self->get_section_field->{de}->set_sensitive(1);
   }

   return 0;
}

# Method:   set_default_focus {{{1
# Purpose:  Set UI focus to the default entry field
sub set_default_focus
{
   my $self = shift;
   $self->get_chapter_field->grab_focus;
}

# }}}1

__PACKAGE__->meta->make_immutable;

1;
