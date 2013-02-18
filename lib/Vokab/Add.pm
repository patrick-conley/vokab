package Vokab::Add;

use strict;
use warnings;
use English qw/ -no-match-vars /;
use utf8;
use feature 'state';

# A package with functions to add new items to the DB. It is not a class; it
# merely provides some encapsulation of the script's functionality.

use Gtk2;
use Log::Handler 'vokab';
use Cwd;
use Params::Validate;

require Exporter;
our @ISA = qw/ Exporter /;
our @EXPORT_OK = qw/ run /;

# Global variables {{{1
my $Source_Path;
BEGIN { $Source_Path = Cwd::abs_path(__FILE__) =~ s![^/]*$!!r; }

my $Log = Log::Handler->get_logger( "vokab" );
my $Saved_Item = undef;
my $DB = undef;

# Use declarations for Vokab classes {{{1
use lib "$Source_Path";
use Vokab::DB;
use Vokab::UI;

use Vokab::Item::Word::Verb;
use Vokab::Item::Word::Noun;
use Vokab::Item::Word::Generic;

# }}}1

# Function: set_item {{{1
# Purpose:  The active Vokab::Item object needs to be in a global variable for
#           reuse; use accessor functions to perform type-checking
# Input:    (Vokab::Item) An object descended from Vokab::Item
# Return:   (bool) Success
sub set_item
{
   state $validation_spec = [ 
      {
         type => Params::Validate::OBJECT,
         isa => 'Vokab::Item',
      }
   ];

   ( $Saved_Item ) = Params::Validate::validate_pos( @_, @$validation_spec );
}

# Function: get_item() {{{1
# Return:   (Vokab::Item) The saved Vokab::Item, or undef. Emits a warning if
#           undef
sub get_item
{
   has_item() or $Log->warning( "Trying to access an undefined Item" );

   return $Saved_Item;
}

# Function: has_item() {{{1
# Return:   (bool) Whether there is a saved Vokab::Item
sub has_item { return defined $Saved_Item }

# }}}1

# Function: run( $dbname ) {{{1
# Purpose:  General handler for adding new Vokab::Items to the DB.
#           Functionality may be relegated to smaller functions
# Input:    N/A
# Return:   N/A
sub run
{
   $DB = Vokab::DB->new( dbname => shift );
   
   $Log->notice( "Creating a window to add items to the DB" );

   # Create a list of known item classes
   my $item_classes = $DB->readall_item_types();
   $Log->debug( "Vokab::Item active subclasses identified:\n" .
      Data::Dumper::Dumper( @$item_classes ) );

   # Last item class selected
   my $previous_item = undef;

   # Create a ComboBox to select the item type {{{2
   my $combo = Gtk2::ComboBox->new();
   my $item_list = Gtk2::ListStore->new( "Glib::String", "Glib::String" );
   $item_list->set( $item_list->append(), 0 => $ARG->[0], 1 => $ARG->[1] ) foreach ( @$item_classes );
   $combo->set_model( $item_list );
   $combo->set_active_iter( $previous_item ) if ( defined $previous_item );

   # Draw the entry window, menus and main grid {{{2

   my $window = Gtk2::Window->new();
   $window->signal_connect(
      destroy => \&Vokab::UI::destroy );
   $window->set_title( "Vokab - Add a new item" );

   my $main_grid = Gtk2::VBox->new();
   $main_grid->set_homogeneous( 0 );
   $window->add( $main_grid );

   Vokab::UI::create_menus( $window );

   # First grid row: select appropriate Vokab::Item leaf class {{{2
   my $row = Gtk2::HBox->new();
   {
      $main_grid->pack_start( $row, 0, 0, 0 );

      # A box for the items
      $row->pack_end( $combo, 0, 0, 0 );

      my $renderer_text = Gtk2::CellRendererText->new();
      $combo->pack_start( $renderer_text, 1 );
      $combo->add_attribute( $renderer_text, "text", 0 );

      # A label
      $row->pack_end( Gtk2::Label->new( "Select the item's type:" ), 0, 1, 0 );
   }

   $window->show_all();

   # Next rows: enter all data needed for a new item {{{2
   my $item_frame = Gtk2::Frame->new();
   {
      $main_grid->pack_start( $item_frame, 0, 0, 0 );

      $combo->signal_connect(
         changed => sub { on_set_item_class( 
               frame => $item_frame,
               prev => \$previous_item,
               combo => $ARG[0] )
         }
      );
   }

   # Last row: 'submit' button (not shown right away) {{{2
   # NB: $window->show_all() shouldn't be called after this row is drawn: it's
   # not shown unless an item class is selected
   my $submit = Gtk2::Button->new_with_label( "Submit" );
   {
      $main_grid->pack_end( $submit, 0, 0, 0 );
      $submit->signal_connect( clicked => \&submit_item );
   }

   # }}}2

   Gtk2->main();
}

# Callback: on_set_item_class() {{{1
# Purpose:  Create and display a new VBox for item entry fields. Acts as a
#           wrapper to set_item_entry_fields() to limit the amount of scope
#           shared.
# Input:    (frame => Gtk::Container) A container to hold the VBox to
#           hold entry fields
sub on_set_item_class
{
   my %args = Params::Validate::validate( @_, {
         frame => { isa => "Gtk2::Container" },
         prev => { type => Params::Validate::SCALARREF },
         combo => { isa => "Gtk2::ComboBox" }
      }
   );

   # Identify the selected class {{{2
   my $selected_class = $args{combo}->get_active_iter();
   defined $selected_class or $Log->die( "No item class is selected. Can't happen?" );

   my $model = $args{combo}->get_model();
   my $class = $model->get( $selected_class, 1 );
   $Log->info( "Selected an item of class "
      . $class . " with name " . $model->get( $selected_class, 0 ) );

   ${$args{previous}} = $selected_class;

   # Reset the box to put items in {{{2
   my ( $box ) = $args{frame}->get_children();
   if ( defined $box )
   {
      $Log->debug( "Removing old item entry box" );
      $args{frame}->remove( $box );
   }
   $box = Gtk2::VBox->new();
   $args{frame}->add( $box );

   # }}}2

   # Create an object and display its entry fields
   draw_item_entry_box( class => $class, box => $box );
   $args{frame}->get_parent->show_all(); # Must show 'submit' button of parent
}

# Function: draw_item_entry_box() {{{1
# Purpose:  Draw the rest of the window once a class has been selected
# Input:    (box => Gtk::VBox) A box to draw entry fields in
#           (class => Vokab::Item) type of item to create.
sub draw_item_entry_box 
{
   my %args = @ARG;

   $Log->info( "Displaying entry window for a " . $args{class} );

   my $item = $args{class}->new( dbh => $DB );
   $item->display_all( box => $args{box} );
}

# Callback: on_submit_item() {{{1
# Purpose:  When a new item's data has been entered, validate and write it.
# Input:    ??
sub submit_item
{
}

# }}}1

1;
