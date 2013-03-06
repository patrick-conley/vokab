package Vokab::Item::Word;

use strict;
use warnings;
use English;
use utf8;
use 5.012;

use Vokab::Types qw/Text/;

# A Vokab::Item::Word is a testable object requiring a literal translation of
# English to Deutsch (although in some cases, a regex may be used to identify
# correct results if the word is ambiguous, eg. "welcome" to "Wilkommen" or
# "herzlich Wilkommen").

use Moose;
extends 'Vokab::Item';

has( 'en'        => ( is => 'rw', isa => Text, init_arg => undef ) );
has( 'de'        => ( is => 'rw', isa => Text, init_arg => undef ) );

foreach my $field ( qw/ en de / )
{
   has $field . "_field" => (
      is => 'ro',
      lazy => 1,
      builder => "_build_${field}_field",
      isa => "Gtk2::Widget",
      init_arg => undef,
   );
}

# Method:   _build_en_field {{{1
# Purpose:  Builder for the en_field attribute
sub _build_en_field
{
   my $self = shift;

   my $entry = Gtk2::Entry->new();
   $entry->set_activates_default(1);
   return $entry;
}

# Method:   _build_de_field {{{1
# Purpose:  Builder for the de_field attribute
sub _build_de_field
{
   my $self = shift;

   my $entry = Gtk2::Entry->new();
   $entry->set_activates_default(1);
   return $entry;
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

   # Get the three columns of the table
   my @item_rows = $args{box}->get_children();
   my @table = $item_rows[-1]->get_children();

   # Col: Labels
   $table[0]->add( Gtk2::Label->new( "English" ) );
   $table[0]->add( Gtk2::Label->new( "Deutsch" ) );

   # Col: English & Deutsch entries
   $table[1]->add( $self->get_en_field );
   $table[1]->add( $self->get_de_field );

   return ( inner() );
};

# Method:   set_all() {{{1
# Purpose:  Set attributes according to the values in entry fields
augment set_all => sub
{
   my $self = shift;
   $self->set_en( $self->get_en_field()->get_text() );
   $self->set_de( $self->get_de_field()->get_text() );

   inner();
};

# Method:   dump() {{{1
# Purpose:  Return a hash of the object's writable attributes
augment dump => sub
{
   my $self = shift;

   my %attrs;
   $attrs{en} = $self->get_en if $self->get_en;
   $attrs{de} = $self->get_de if $self->get_de;

   return (
      %attrs,
      inner()
   );
};

# Method:   set_default_focus {{{1
# Purpose:  Set UI focus to the defualt entry field
sub set_default_focus
{
   my $self = shift;
   $self->get_en_field->grab_focus;
}

# }}}1

__PACKAGE__->meta->make_immutable;

1;
