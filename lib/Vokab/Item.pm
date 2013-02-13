package Vokab::Item;

use strict;
use warnings;
use English;
use utf8;

# A Vokab::Item is meant to be used for any testable object.

use Gtk2;
use Params::Validate;

use Moose;
use MooseX::FollowPBP; # use get_, set_ accessors
use namespace::autoclean; # clean up Moose droppings

has 'log' => ( is => 'ro', # Log::Handler object for debugging output
               default => sub { return Log::Handler->get_logger("vokab"); },
               reader => 'log',   # override Moose::FollowPBP
               lazy => 1,         # don't set it until used
               init_arg => undef, # don't allow this to be set with new()
               required => 1,
               isa => 'Log::Handler'
             );
has 'dbh' => ( is => 'ro', # Database handler
               reader => 'dbh',
               required => 1,
               isa => 'DBI::db'
             );

has 'id' => ( is => 'rw' );
has 'class' => ( is => 'rw' );
has 'chapter' => ( is => 'rw' );
has 'section' => ( is => 'rw' );
has 'tests' => ( is => 'rw' );
has 'success' => ( is => 'rw' );
has 'score' => ( is => 'rw' );

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

   # Table: Section + various children
   my $table = Gtk2::HBox->new();
   {
      $args{box}->add( $table );
      $table->set_homogeneous( 0 );

      # Col: Label
      my $col = Gtk2::VBox->new();
      {
         $table->add( $col );
         $col->add( Gtk2::Label->new( "Section " ) );
      }

      # Col: Section entry
      $col = Gtk2::VBox->new();
      {
         $table->add( $col );
         my $section_field = Gtk2::Entry->new();
         $col->add( $section_field );
      }

      # Col: comments
      $col = Gtk2::VBox->new();
      {
         $table->add( $col );

         my $row = Gtk2::HBox->new();
         {
            $col->pack_start( $row, 0, 0, 0 );

            $row->add( Gtk2::Label->new( "Chapter" ) );
            my $chapter_field = Gtk2::SpinButton->new_with_range( 0, 100, 1 );
            $row->pack_end( $chapter_field, 0, 0, 0 );
         }
      }
   }

   inner();
}

# }}}1

__PACKAGE__->meta->make_immutable;

1;
