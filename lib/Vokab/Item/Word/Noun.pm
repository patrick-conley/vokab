package Vokab::Item::Word::Noun;

use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;

# A Vokab::Item::Word::Noun is a noun. It will ordinarilly have a specified
# gender, and the translation must include the correct pronoun. The plural
# form must also be entered. Certain words (eg., "friend") may allow both the
# masculine and feminine, in which case both must be correctly given.

use Moose;
extends 'Vokab::Item::Word';

has 'gender' => ( is => 'rw' );
has 'display_gender' => ( is => 'rw' );

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

   # NOTE: hacks follow. Vokab::Item::Word creates a single VBox containing
   # the En/De fields;
   # A comment on the field contents should be added to the right
   # The gender should be added below

   # Append a comment to the language row
   my @item_rows = $args{box}->get_children();
   my @table = $item_rows[-1]->get_children();

   # Col: Label
   $table[0]->add( Gtk2::Label->new( "Gender" ) );

   # Col: Gender entry & display checkbox
   my $row = Gtk2::HBox->new();
   {
      $table[1]->add( $row );
      my $gender_field = Gtk2::Entry->new_with_max_length(1);
      $gender_field->set_width_chars( 2 ); # 'm' is too wide for 1
      $row->pack_start( $gender_field, 0, 0, 0 ); # Don't expand

      my $gender_shown_field = Gtk2::CheckButton->new("Display gender?");
      $gender_shown_field->set_tooltip_text( "Set whether to display the item's gender in a quiz (appropriate for multi-gendered items, eg.  Freund/Freundin)" );
      $row->add( $gender_shown_field );
   }

   # Col: Comment
   $table[2]->add( Gtk2::Label->new( 
         "Don't include any article\n('the', 'der', 'die', or 'das')" )
   );

   inner();
};

# }}}1

__PACKAGE__->meta->make_immutable;

1;
