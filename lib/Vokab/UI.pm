package Vokab::UI;

use strict;
use warnings;
use English qw/ -no-match-vars /;
use utf8;

use Gtk2;
use Log::Handler 'vokab' ;

my $Log = Log::Handler->get_logger( 'vokab' );

# Handler:  handle_ui_exceptions() {{{1
# Purpose:  A common error-handler for Gtk objects
# Input:    $@
sub handle_ui_exceptions
{
   my $msg = shift;

   my $window_msg = $msg =~ s/\n.*//sr; # only display the first line

   my $window = Gtk2::MessageDialog->new(
      undef,"destroy_with_parent", "GTK_MESSAGE_ERROR",
      "close", "Gtk threw an exception:\n %s", $window_msg );
   $window->run();
   $window->destroy();

   Gtk2->main_quit();

   $Log->alert( "Gtk threw an exception: $msg" );
}

# Function: create_menus() {{{1
# Purpose:  Create a menu and set some accelerators
# Input:    (Gtk2::Window) window object
# Return:   N/A
sub create_menus
{
   my $window = shift;

   $Log->info( "Setting up menus for a window named '"
      . $window->get_title() . "'" );

   my $ui_info = "
   <ui>
      <menubar name='MenuBar'>
         <menu action='FileMenu'>
            <menuitem action='Quit'/>
         </menu>
      </menubar>
   </ui>";

   my $actions = Gtk2::ActionGroup->new('Actions');
   $actions->add_actions( [
         [ 'FileMenu', undef, 'File' ],
         [ 'Quit', 'gtk-quit', 'Quit', '<control>Q', 'Quit the program',
            sub { Gtk2->main_quit } ] ] );

   my $ui = Gtk2::UIManager->new();
   $ui->insert_action_group( $actions, 0 );
   $ui->add_ui_from_string( $ui_info );

   $window->add_accel_group( $ui->get_accel_group );
   $window->get_child->pack_start( $ui->get_widget( '/MenuBar' ), 0, 0, 0 );
}

# }}}1

