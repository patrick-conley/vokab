package Vokab::Item::Word::Verb;

use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;
use 5.012;

use Vokab::Types qw/Verb/;

use Moose;
extends 'Vokab::Item::Word';

# Conjugation:
# A hashref with keys qw/ ich du er Sie wir ihr sie /
# Some keys can be autodefined:
# wir,sie,Sie == undef <= infinitive
# ihr,er == undef <= er,ihr (at least one must be defined)
has( 'conjugation' => ( is => 'rw', isa => Verb, init_arg => undef ) );

foreach my $field ( qw/ ich du er Sie wir ihr sie / )
{
   has $field . "_field" => (
      is => 'ro',
      lazy => 1,
      default => sub { return Gtk2::Entry->new() },
      isa => "Gtk2::Widget",
      init_arg => undef,
   );
}

# A Vokab::Item::Word::Verb is a *conjugated* verb. When entering a new item,
# each person must be entered, but in selecting a verb only one person is
# given.

# Method:   display_all( box => $box ) {{{1
# Purpose:  Display entry fields for everything the item needs
# Input:    (Gtk::VBox) a box to hold everything
augment display_all => sub
{
   # Get args
   my $self = shift;
   my %args = Params::Validate::validate( @_, {
         box => { isa => "Gtk2::Box" }
      }
   );

   # Append a comment to the language row
   my @rows = $args{box}->get_children();
   $rows[-1]->add( Gtk2::Label->new( "Infinitive goes here!" ) );

   $args{box}->add( Gtk2::Label->new(
         "Enter the conjugation for simple present in Deutsch:" )
   );

   my $conj_row = Gtk2::HBox->new();
   {
      $args{box}->add( $conj_row );

      my $col = Gtk2::VBox->new();
      {
         $conj_row->add( $col );
         $col->add( Gtk2::Label->new( "ich" ) );
         $col->add( Gtk2::Label->new( "du" ) );
         $col->add( Gtk2::Label->new( "Sie" ) );
         $col->add( Gtk2::Label->new( "er" ) );
      }

      $col = Gtk2::VBox->new();
      {
         $conj_row->add( $col );

         $col->pack_start( $self->get_ich_field, 0, 0, 0 );
         $col->pack_start( $self->get_du_field, 0, 0, 0 );
         $col->pack_start( $self->get_Sie_field, 0, 0, 0 );
         $col->pack_start( $self->get_er_field, 0, 0, 0 );
      }

      $col = Gtk2::VBox->new();
      {
         $conj_row->add( $col );

         $col->pack_start( $self->get_wir_field, 0, 0, 0 );
         $col->pack_start( $self->get_ihr_field, 0, 0, 0 );
         $col->pack_start( $self->get_sie_field, 0, 0, 0 );
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

# Method:   set_all() {{{1
# Purpose:  Set attributes according to the values in entry fields
augment set_all => sub
{
   my $self = shift;

   my $conjugation = {};
   foreach my $key ( qw/ ich du er Sie wir ihr sie / )
   {
      my $getter = "get_${key}_field";
      my $text = $self->$getter->get_text();
      $conjugation->{$key} = $text if $text;
   }

   $self->set_conjugation( $conjugation );
};

# Method:   dump() {{{1
# Purpose:  Return a hash of the object's writable attributes
augment dump => sub
{
   my $self = shift;

   my %attrs = @$self->get_conjugation if $self->get_conjugation;

   return (
      %attrs,
      inner()
   );
};

# }}}1

__PACKAGE__->meta->make_immutable;

1;
