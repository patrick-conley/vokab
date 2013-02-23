package Vokab::Item::Word::Verb;

use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;

use Vokab::Types qw/Text/;

use Moose;
extends 'Vokab::Item::Word';

has 'conjugation' => ( is => 'rw', isa => 'HashRef[Text]', init_arg => undef );

foreach my $field ( qw/ conjugation / )
{
   has $field . "_field" => (
      is => 'rw',
      lazy => 1,
      builder => "_build_${field}_field",
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

   my $conj = {
      s1 => Gtk2::Entry->new(),
      s2 => Gtk2::Entry->new(),
      f2 => Gtk2::Entry->new(),
      s3 => Gtk2::Entry->new(),
      p1 => Gtk2::Entry->new(),
      p2 => Gtk2::Entry->new(),
      p3 => Gtk2::Entry->new(),
   };
   return $conj;
}

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

         $col->pack_start( $self->get_conjugation_field->{s1}, 0, 0, 0 );
         $col->pack_start( $self->get_conjugation_field->{s2}, 0, 0, 0 );
         $col->pack_start( $self->get_conjugation_field->{f2}, 0, 0, 0 );
         $col->pack_start( $self->get_conjugation_field->{s3}, 0, 0, 0 );
      }

      $col = Gtk2::VBox->new();
      {
         $conj_row->add( $col );

         $col->pack_start( $self->get_conjugation_field->{p1}, 0, 0, 0 );
         $col->pack_start( $self->get_conjugation_field->{p2}, 0, 0, 0 );
         $col->pack_start( $self->get_conjugation_field->{p3}, 0, 0, 0 );
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
   foreach my $key ( keys $self->get_conjugation_field )
   {
      my $text = $self->get_conjugation_field()->{$key}->get_text();
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

# }}}1

__PACKAGE__->meta->make_immutable;

1;
