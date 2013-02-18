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
         $col->add( Gtk2::Label->new( "ich" ) );
         $col->add( Gtk2::Label->new( "du" ) );
         $col->add( Gtk2::Label->new( "er" ) );
         $col->add( Gtk2::Label->new( "Sie" ) );
      }

      $col = Gtk2::VBox->new();
      {
         $conj_row->add( $col );

         $people[0] = Gtk2::Entry->new();
         $col->pack_start( $people[0], 0, 0, 0 );

         $people[1] = Gtk2::Entry->new();
         $col->pack_start( $people[1], 0, 0, 0 );

         $people[2] = Gtk2::Entry->new();
         $col->pack_start( $people[2], 0, 0, 0 );

         $people[3] = Gtk2::Entry->new();
         $col->pack_start( $people[3], 0, 0, 0 );
      }

      $col = Gtk2::VBox->new();
      {
         $conj_row->add( $col );

         $people[4] = Gtk2::Entry->new();
         $col->pack_start( $people[4], 0, 0, 0 );

         $people[5] = Gtk2::Entry->new();
         $col->pack_start( $people[5], 0, 0, 0 );

         $people[6] = Gtk2::Entry->new();
         $col->pack_start( $people[6], 0, 0, 0 );

      }

      $col = Gtk2::VBox->new();
      {
         $conj_row->add( $col );
         $col->add( Gtk2::Label->new( "wir" ) );
         $col->add( Gtk2::Label->new( "ihr" ) );
         $col->add( Gtk2::Label->new( "sie" ) );
         $col->add( Gtk2::Label->new( "" ) );
      }

   }
};

__PACKAGE__->meta->make_immutable;

1;
