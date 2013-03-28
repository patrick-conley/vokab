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

foreach my $field ( qw/ conjugation / )
{
   has $field . "_field" => (
      is => 'ro',
      lazy => 1,
      builder => "_build_${field}_field",
      isa => "HashRef[Gtk2::Widget]",
      init_arg => undef,
   );
}

# A Vokab::Item::Word::Verb is a *conjugated* verb. When entering a new item,
# each person must be entered, but in selecting a verb only one person is
# given.

# Method:   _build_conjugation_field {{{1
# Purpose:  Builder for the conjugation_field attribute
sub _build_conjugation_field
{
   my $self = shift;

   sub entry_builder
   {
      my $entry = Gtk2::Entry->new();
      $entry->set_activates_default(1);
      return $entry;
   }

   my $conj = {
      ich => entry_builder,
      du => entry_builder,
      Sie => entry_builder,
      er => entry_builder,
      wir => entry_builder,
      ihr => entry_builder,
      sie => entry_builder,
   };
   return $conj;
}

# Method:   display_all( box => $box ) {{{1
# Purpose:  Display entry fields for everything the item needs
# Input:    (Gtk::VBox) a box to hold everything
# Return:   (array) Contents of a label describing what should be entered
augment display_all => sub
{
   # Get args
   my $self = shift;
   my %args = Params::Validate::validate( @_, {
         box => { isa => "Gtk2::Box" }
      }
   );

   my $label = Gtk2::Label->new(
      'Enter the conjugation for simple present in Deutsch. "Wir"/"sie"/"Sie"'
      . 'and "ihr" will be computed from the infinitive and "er" if they are'
      . 'left blank' );
   $label->set_line_wrap(1);

   $args{box}->add( $label );

   my $conj_row = Gtk2::HBox->new();
   {
      $args{box}->add( $conj_row );

      my $col = Gtk2::VBox->new();
      {
         $conj_row->add( $col );
         $col->add( Gtk2::Label->new( "ich" ) );
         $col->add( Gtk2::Label->new( "du" ) );
         $col->add( Gtk2::Label->new( "er" ) );
         $col->add( Gtk2::Label->new( "" ) );
      }

      $col = Gtk2::VBox->new();
      {
         $conj_row->add( $col );

         $col->pack_start( $self->get_conjugation_field->{ich}, 0, 0, 0 );
         $col->pack_start( $self->get_conjugation_field->{du}, 0, 0, 0 );
         $col->pack_start( $self->get_conjugation_field->{er}, 0, 0, 0 );
      }

      $col = Gtk2::VBox->new();
      {
         $conj_row->add( $col );

         $col->pack_start( $self->get_conjugation_field->{wir}, 0, 0, 0 );
         $col->pack_start( $self->get_conjugation_field->{ihr}, 0, 0, 0 );
         $col->pack_start( $self->get_conjugation_field->{sie}, 0, 0, 0 );
         $col->pack_start( $self->get_conjugation_field->{Sie}, 0, 0, 0 );
      }

      $col = Gtk2::VBox->new();
      {
         $conj_row->add( $col );
         $col->add( Gtk2::Label->new( "wir" ) );
         $col->add( Gtk2::Label->new( "ihr" ) );
         $col->add( Gtk2::Label->new( "sie" ) );
         $col->add( Gtk2::Label->new( "Sie" ) );
      }

   }

   return ( '"en" and "de" fields should contain the infinitive', inner() );
};

# Method:   set_all() {{{1
# Purpose:  Set attributes according to the values in entry fields
augment set_all => sub
{
   my $self = shift;

   my $conj = {};
   foreach my $key ( keys $self->get_conjugation_field )
   {
      my $text = $self->get_conjugation_field()->{$key}->get_text();
      $conj->{$key} = $text if $text;
   }

   # Set autodefinable keys

   # wir/sie/Sie
   foreach my $key ( grep { ! defined $conj->{$ARG} } qw/ wir sie Sie / )
   {
      $conj->{$key} = $self->get_de;
   }

   # er/ihr
   $conj->{er} = $conj->{ihr} if ( ! defined $conj->{er} );
   $conj->{ihr} = $conj->{er} if ( ! defined $conj->{ihr} );

   $self->set_conjugation( $conj );
};

# Method:   write_all() {{{1
# Purpose:  Call the DBH to write a new item
augment write_all => sub
{
   my $self = shift;
   $self->db->write_verb( %{$self->get_conjugation} );

   inner();
};

# Method:   dump() {{{1
# Purpose:  Return a hash of the object's writable attributes
augment dump => sub
{
   my $self = shift;

   my %attrs = %{$self->get_conjugation} if $self->get_conjugation;

   return (
      %attrs,
      inner()
   );
};

# }}}1

# }}}1

__PACKAGE__->meta->make_immutable;

1;
