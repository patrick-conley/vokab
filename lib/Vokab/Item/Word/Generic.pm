package Vokab::Item::Word::Generic;

use strict;
use warnings;
use English qw/ -no-match-vars /;
use utf8;
use 5.012;

use MooseX::Types::Moose qw/ Str /;

# A Vokab::Item::Word::Generic is meant to capture words or phrases with no
# special properties.

use Moose;
extends 'Vokab::Item::Word';

has( 'alternate' => ( is => 'rw', isa => Str, init_arg => undef ) );

foreach my $field ( qw/ alternate / )
{
   has $field . "_field" => (
      is => 'ro',
      lazy => 1,
      builder => "_build_${field}_field",
      isa => "Gtk2::Widget",
      init_arg => undef,
   );
}

# Method:   _build_alternate_field {{{1
# Purpose:  Builder for the alternate_field attribute
sub _build_alternate_field
{
   my $self = shift;

   my $entry = Gtk2::Entry->new();
   $entry->set_tooltip_text(
      "A regex matching all possible correct answers (optional)"
   );
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
   $table[0]->add( Gtk2::Label->new( "Alternate" ) );

   # Col: English & Deutsch entries
   $table[1]->add( $self->get_alternate_field );

   return ( inner() );
};

# Method:   set_all() {{{1
# Purpose:  Set attributes according to the values in entry fields
augment set_all => sub
{
   my $self = shift;
   $self->set_alternate( $self->get_alternate_field()->get_text() );

   inner();
};

# Method:   write_all() {{{1
# Purpose:  Call the DBH to write a new item
augment write_all => sub
{
   my $self = shift;
   $self->db->write_generic( alternate => $self->get_alternate );

   inner();
};
# Method:   dump() {{{1
# Purpose:  Return a hash of the object's writable attributes
augment dump => sub
{
   my $self = shift;

   my %attrs;
   $attrs{alternate} = $self->get_alternate if $self->get_alternate;

   return (
      %attrs,
      inner()
   );
};

# }}}1

__PACKAGE__->meta->make_immutable;

1;
