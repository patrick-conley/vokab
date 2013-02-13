package Vokab::Item::Word::Verb;

use strict;
use warnings;
use utf8;

use Moose;
extends 'Vokab::Item::Word';

has 'person' => ( is => 'ro' );

# A Vokab::Item::Word::Verb is a *conjugated* verb. When entering a new item,
# each person must be entered, but in selecting a verb only one person is
# given.

augment display_all => sub
{
   # Get args
   my $self = shift;
   my %args = Params::Validate::validate( @_, {
         box => { isa => "Gtk2::Box" }
      }
   );

   my @people;

   # Append a comment to the language row
   my @rows = $args{box}->get_children();
   $rows[-1]->add( Gtk2::Label->new( "Infinitive goes here!" ) );

   $args{box}->add( Gtk2::Label->new(
         "Enter each person's conjugation in Deutsch:" )
   );

   my $conj_row = Gtk2::HBox->new();
   {
      $args{box}->add( $conj_row );

      my $col = Gtk2::VBox->new();
      {
         $conj_row->add( $col );
         $col->add( Gtk2::Label->new( "" ) ); # blank line
         $col->add( Gtk2::Label->new( "1st person" ) );
         $col->add( Gtk2::Label->new( "2nd informal" ) );
         $col->add( Gtk2::Label->new( "3rd person" ) );
         $col->add( Gtk2::Label->new( "2nd formal" ) );
      }

      $col = Gtk2::VBox->new();
      {
         $conj_row->add( $col );
         $col->add( Gtk2::Label->new( "singular" ) );

         my $row = Gtk2::HBox->new();
         {
            $col->add( $row );
            $people[0] = Gtk2::Entry->new();
            $row->add( $people[0] );
         }

         $row = Gtk2::HBox->new();
         {
            $col->add( $row );
            $people[1] = Gtk2::Entry->new();
            $row->add( $people[1] );
         }

         $row = Gtk2::HBox->new();
         {
            $col->add( $row );
            $people[2] = Gtk2::Entry->new();
            $row->add( $people[2] );
         }

         $row = Gtk2::HBox->new();
         {
            $col->add( $row );
            $people[3] = Gtk2::Entry->new();
            $row->add( $people[3] );
         }
      }

      $col = Gtk2::VBox->new();
      {
         $conj_row->add( $col );
         $col->add( Gtk2::Label->new( "plural" ) );

         my $row = Gtk2::HBox->new();
         {
            $col->add( $row );
            $people[4] = Gtk2::Entry->new();
            $row->add( $people[4] );
         }

         $row = Gtk2::HBox->new();
         {
            $col->add( $row );
            $people[5] = Gtk2::Entry->new();
            $row->add( $people[5] );
         }

         $row = Gtk2::HBox->new();
         {
            $col->add( $row );
            $people[6] = Gtk2::Entry->new();
            $row->add( $people[6] );
         }

         $row = Gtk2::HBox->new();
         $row->add( Gtk2::Label->new( "" ) );
         $col->add( $row );
      }
   }
};

__PACKAGE__->meta->make_immutable;

1;
