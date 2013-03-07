package Vokab::Add;

use strict;
use warnings;
use English qw/ -no-match-vars /;
use utf8;
use 5.012;

# A package with functions to add new items to the DB. It is not a class; it
# merely provides some encapsulation of the script's functionality.

use Gtk2;
use Log::Handler 'vokab';
use Cwd;
use Params::Validate;
use Data::Dumper;
use TryCatch;

require Exporter;
our @ISA = qw/ Exporter /;
our @EXPORT_OK = qw/ run /;

# Global variables {{{1
my $Source_Path;
BEGIN { $Source_Path = Cwd::abs_path(__FILE__) =~ s![^/]*$!!r; }

my $Log = Log::Handler->get_logger( "vokab" );
my $DB = undef;

my $Active_Item = undef;
my $Class_Selection_Box = undef;
my $Item_Frame = undef;

# Function: set_item {{{2
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
   ( $Active_Item ) = Params::Validate::validate_pos( @ARG, @$validation_spec );
}

# Function: get_item() {{{2
# Return:   (Vokab::Item) The saved Vokab::Item, or undef. Emits a warning if
#           undef
sub get_item
{
   has_item() or $Log->warning( "Trying to access an undefined Item" );
   return $Active_Item;
}

# Function: has_item() {{{2
# Return:   (bool) Whether there is a saved Vokab::Item
sub has_item { return defined $Active_Item }

# }}}2

# Use declarations for Vokab classes {{{1
use lib "$Source_Path";
use Vokab::DB;
use Vokab::UI;

use Vokab::Item::Word::Verb;
use Vokab::Item::Word::Noun;
use Vokab::Item::Word::Generic;

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
   my $window = Vokab::UI::new_window( title => "Add a new item" );
   my $main_grid = $window->get_child();

   # Create a list of known item classes
   my $item_classes = $DB->readall_item_types();
   $Log->debug( "Vokab::Item active subclasses identified:\n" .
      Data::Dumper::Dumper( @$item_classes ) );

   # Create a ComboBox to select the item type {{{2
   $Class_Selection_Box = Gtk2::ComboBox->new();
   my $item_list = Gtk2::ListStore->new( "Glib::String", "Glib::String" );
   foreach my $class ( @$item_classes )
   {
      $item_list->set( $item_list->append(), 0 => $class->[0], 1 => $class->[1] );
   }
   $Class_Selection_Box->set_model( $item_list );

   # First grid row: select appropriate Vokab::Item leaf class {{{2
   my $row = Gtk2::HBox->new();
   {
      $main_grid->pack_start( $row, 0, 0, 0 );

      # A box for the items
      $row->pack_end( $Class_Selection_Box, 0, 0, 0 );

      my $renderer_text = Gtk2::CellRendererText->new();
      $Class_Selection_Box->pack_start( $renderer_text, 1 );
      $Class_Selection_Box->add_attribute( $renderer_text, "text", 0 );

      # A label
      $row->pack_end( Gtk2::Label->new( "Select the item's type:" ), 0, 1, 0 );
   }

   $window->show_all();

   # Next rows: enter all data needed for a new item {{{2
   $Item_Frame = Gtk2::Frame->new();
   {
      $main_grid->pack_start( $Item_Frame, 0, 0, 0 );
   }

   $Class_Selection_Box->signal_connect( changed => \&on_set_item_class );

   # Last row: 'submit' button (not shown right away) {{{2
   # NB: $window->show_all() shouldn't be called after this row is drawn: it's
   # not shown unless an item class is selected
   my $submit = Gtk2::Button->new_with_label( "Submit" );
   {
      $main_grid->pack_end( $submit, 0, 0, 0 );
      $submit->signal_connect( clicked => \&on_submit_item );
      $submit->set_flags( "can_default" );
      $window->set_default( $submit );
   }

   # }}}2

   Gtk2->main();
}

# Callback: on_set_item_class() {{{1
# Purpose:  Create and display a new VBox for item entry fields. Acts as a
#           wrapper to set_item_entry_fields() to limit the amount of scope
#           shared.
# Input:    N/A
sub on_set_item_class
{
   # Identify the selected class {{{2
   my $selected_class = $Class_Selection_Box->get_active_iter();
   defined $selected_class
      or $Log->die( "No item class is selected. Can't happen?" );

   my $model = $Class_Selection_Box->get_model();
   my $class = $model->get( $selected_class, 1 );
   $Log->info( "Selected an item of class "
      . $class . " with name " . $model->get( $selected_class, 0 ) );

   # Reset the box to put items in {{{2
   my ( $box ) = $Item_Frame->get_children();
   if ( defined $box )
   {
      $Log->debug( "Removing old item entry box" );
      $Item_Frame->remove( $box );
   }
   $box = Gtk2::VBox->new();
   $Item_Frame->add( $box );

   # }}}2

   # Create an object and display its entry fields
   draw_item_entry_box( class => $class, box => $box );
   $Item_Frame->get_parent->show_all(); # Must show 'submit' button of parent
}

# Function: draw_item_entry_box() {{{1
# Purpose:  Draw the rest of the window once a class has been selected
# Input:    (box => Gtk::VBox) A box to draw entry fields in
#           (class => Vokab::Item) type of item to create.
sub draw_item_entry_box 
{
   state $validation_spec = {
      class => {
         type => Params::Validate::SCALAR,
         regex => qr/^Vokab::Item::/,
      },
      box => { 
         isa => "Gtk2::Box" 
      }
   };
   my %args = Params::Validate::validate( @ARG, $validation_spec );

   $Log->info( "Displaying entry window for a " . $args{class} );

   my $item = has_item()
      ? $args{class}->new( db => $DB, get_item()->dump() )
      : $args{class}->new( db => $DB );
   $item->display_all( box => $args{box} );
   set_item( $item );
}

# Callback: on_submit_item() {{{1
# Purpose:  When a new item's data has been entered, validate and write it.
# Input:    
sub on_submit_item
{
   has_item()
      or $Log->alert( "Callback out of place: Can't submit an undefined item.");

   my $item = get_item();
   try 
   {
      $item->set_all();
   }
   catch ( $e =~ /Attribute \(.*\) does not pass the type constraint/ )
   {
      Vokab::UI::handle_ui_exceptions( $e );
      $Log->dump( warning => $e =~ s/\n.*//sr );

      # Select the field that caused the error
      my ( $e_attr ) = $e =~ /Attribute \((.*)\) does not pass/;
      my $get = "get_${e_attr}_field";
      $item->$get->grab_focus;

      return 1;
   }

   # Create a new item, copying over field contents where appropriate
   on_set_item_class();
   get_item->set_default_focus();
}

# }}}1

1;
