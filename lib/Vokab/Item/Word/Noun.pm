package Vokab::Item::Word::Noun;

use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;
use 5.012;

use Vokab::Types qw/ Gender Noun /;
use MooseX::Types::Moose qw/ Bool /;

# A Vokab::Item::Word::Noun is a noun. It will ordinarilly have a specified
# gender, and the translation must include the correct pronoun. The plural
# form must also be entered. Certain words (eg., "friend") may allow both the
# masculine and feminine, in which case both must be correctly given.

use Moose;
extends 'Vokab::Item::Word';

has( 'gender'         => ( is => 'rw', isa => Gender, init_arg => undef ) );
has( '+en'             => ( isa => Noun ) );
has( '+de'             => ( isa => Noun ) );

foreach my $field ( qw/ gender / )
{
   has $field . "_field" => (
      is => 'ro',
      lazy => 1,
      builder => "_build_${field}_field",
      isa => "Gtk2::Widget",
      init_arg => undef,
   );
}

# Method:   _build_gender_field {{{1
# Purpose:  Builder for the gender_field attribute
sub _build_gender_field
{
   my $self = shift;

   my $entry = Gtk2::Entry->new_with_max_length(1);
   $entry->set_width_chars( 2 ); # 'm' is too wide for 1
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

   # NOTE: hacks follow. Vokab::Item::Word creates a single VBox containing
   # the En/De fields:
   # Add a new VBox with a comment on the contents of En/De; add the gender
   # below

   # Append a comment to the language row
   my @item_rows = $args{box}->get_children();
   my @table = $item_rows[-1]->get_children();

   # Col: Label
   $table[0]->add( Gtk2::Label->new( "Gender" ) );

   # Col: Gender entry & display checkbox
   my $row = Gtk2::HBox->new();
   {
      $table[1]->add( $row );
      $row->pack_start( $self->get_gender_field, 0, 0, 0 ); # Don't expand
   }

   return ( '"en" and "de" fields should not include the article '
      . '("the", "der", "die", or "das")', 
      'Select "display gender" if there are testable words with different
      genders: eg., "friend" → "der Freund" or "die Freundin"', inner() );
};

# Method:   set_all() {{{1
# Purpose:  Set attributes according to the values in entry fields
augment set_all => sub
{
   my $self = shift;

   $self->set_gender( $self->get_gender_field()->get_text() );
};

# Method:   write_all() {{{1
# Purpose:  Call the DBH to write a new item
augment write_all => sub
{
   my $self = shift;
   
   $self->db->write_noun(
      id => $self->get_id,
      gender => $self->get_gender,
   );

   inner();
};

# Method:   dump() {{{1
# Purpose:  Return a hash of the object's writable attributes
augment dump => sub
{
   my $self = shift;

   return (
      gender => $self->get_gender,
   );
};


# }}}1

__PACKAGE__->meta->make_immutable;

1;
