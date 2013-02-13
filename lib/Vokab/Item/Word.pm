package Vokab::Item::Word;

use strict;
use warnings;
use English;
use utf8;

# A Vokab::Item::Word is a testable object requiring a literal translation of
# English to Deutsch (although in some cases, a regex may be used to identify
# correct results if the word is ambiguous, eg. "welcome" to "Wilkommen" or
# "herzlich Wilkommen").

use Moose;
extends 'Vokab::Item';

has 'en' => ( is => 'rw' );
has 'de' => ( is => 'rw' );
has 'match' => ( is => 'rw' );

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

   my @item_rows = $args{box}->get_children();
   my @table = $item_rows[-1]->get_children();

   # Col: Labels
   $table[0]->add( Gtk2::Label->new( "English" ) );
   $table[0]->add( Gtk2::Label->new( "Deutsch" ) );

   # Col: English & Deutsch entries
   my $english_field = Gtk2::Entry->new();
   $table[1]->add( $english_field );
   my $deutsch_field = Gtk2::Entry->new();
   $table[1]->add( $deutsch_field );

   inner();
};

# }}}1

__PACKAGE__->meta->make_immutable;

1;
