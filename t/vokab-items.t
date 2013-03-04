use strict;
use warnings;
use English qw/ -no-match-vars /;
use utf8;

use Test::Most tests => 344;
use Gtk2 '-init';

BEGIN
{
   die_on_fail();
   use_ok( "Vokab::Item" );
   use_ok( "Vokab::Item::Word" );
   use_ok( "Vokab::Item::Word::Noun" );
   use_ok( "Vokab::Item::Word::Verb" );
   use_ok( "Vokab::Item::Word::Generic" );
   restore_fail();
}

# Info about Gtk2 entry field types {{{1
my $Gtk_types = {
   SpinButton => {
      getter => "get_value_as_int",
      setter => "set_value"
   },
   Entry => {
      getter => "get_text",
      setter => "set_text",
   },
   CheckButton => {
      getter => "get_active",
      setter => "set_active",
   },
};

# Data on entry attributes {{{1
# Notes:
# - if Gtk_type is defined and attrs->[i]->{bad} is not an empty list, then
#   the first value in the list *must* be something that Gtk will accept
#   without errors or warnings. This value is used by test_set_all, and
#   assumes that it passes Gtk's validation.
my $data = {
   'Vokab::Item' => {
      class => 'Vokab::Item',
      attrs => [
         {
            name => 'id', Moose_type => 'Natural', init => 0,
            good => [ 1, 35 ],
            bad => [ -1, 'foo' ],
         },
         {
            name => 'class', Moose_type => 'ClassName', init => 0,
            good => [ 'Vokab::Item::Word::Noun' ],
            bad => [ 'foo', 'Vokab::Item::Foo' ]
         }, 
         {
            name => 'tests', Moose_type => 'Natural', init => 0,
            good => [ 0, 1 ],
            bad => [ -1, 'foo' ]
         }, 
         {
            name => 'success', Moose_type => 'Natural', init => 0,
            good => [ 0, 1 ],
            bad => [ -1, 'foo' ]
         }, 
         {
            name => 'score', Moose_type => 'Real', init => 0,
            good => [ 0, 1, 0.8 ],
            bad => [ -0.1, 1.1, 'foo' ]
         }, 
         {
            name => 'chapter', init => 1,
            Gtk_type => "SpinButton", Moose_type => 'Natural',
            good => [ 1 ],
            bad => []
         },
         {
            name => 'section', init => 1,
            Gtk_type => "Entry", Moose_type => 'OptText',
            good => [ 'foo', '' ],
            bad => [ 1 ]
         },
      ],
   },
   'Vokab::Item::Word' => {
      class => 'Vokab::Item::Word',
      attrs => [
         {
            name => 'en', init => 0,
            Gtk_type => "Entry", Moose_type => 'Text',
            good => [ 'foo', 'the foo' ],
            bad => [ 1, undef ]
         },
         {
            name => 'de', init => 0,
            Gtk_type => "Entry", Moose_type => 'Text',
            good => [ 'bar', 'der bar' ],
            bad => [ 1, undef ]
         },
         {
            name => 'alternate', init => 0,
            Gtk_type => "Entry", Moose_type => 'Str',
            good => [ '/(foo|bar)+/', '' ],
            bad => []
         },
      ],
   },
   'Vokab::Item::Word::Noun' => {
      class => 'Vokab::Item::Word::Noun',
      attrs => [
         {
            name => 'gender', init => 0,
            Gtk_type => "Entry", Moose_type => 'Gender',
            good => [ 'm', 'f', 'n' ],
            bad => [ 1, undef, 'a', 'e' ]
         },
         {
            name => 'display_gender', init => 0,
            Gtk_type => "CheckButton", Moose_type => 'Bool',
            good => [ '', 1 ],
            bad => []
         },
         {
            name => 'en', init => 0,
            Gtk_type => "Entry", Moose_type => 'Noun',
            good => [ 'foo' ],
            bad => [ 1, 'the foo', undef ]
         }, 
         {
            name => 'de', init => 0,
            Gtk_type => "Entry", Moose_type => 'Noun',
            good => [ 'bar' ],
            bad => [ 1, 'der bar', 'die bar', 'das bar', undef ]
         }, 
      ],
   },
   'Vokab::Item::Word::Verb' => {
      class => 'Vokab::Item::Word::Verb',
      attrs => [
         {
            name => 'conjugation', init => 0,
            Gtk_type => "HashRef[Entry]", Moose_type => "Verb",
            good => [
               { ich => 'foo', du => 'foo', er => 'foo', Sie => 'foo',
                  wir => 'foo', ihr => 'foo', sie => 'foo'
               } ],
            bad => [ { wir => 'foo' }, undef, "" ],
         },
      ],
   },
   'Vokab::Item::Word::Generic' => {
      class => 'Vokab::Item::Word::Generic',
      attrs => [],
   },
};
# }}}1

# Function: test_attributes {{{1
# Purpose:  Test class initializers and accessors.
# Input:    (hashref) {
#              class => class_name,
#              attrs => [
#                 name => attr_name, init => set from new()?,
#                 Gtk_type => Gtk2::Object desc., Moose_type => type,
#                 good => [ list of valid values ],
#                 bad => [ list of bad attrs ],
#              ] }
sub test_attributes
{
   my $class = shift;

   my $obj;
   my ( $get, $set );
   my $printable;

   foreach my $attr ( grep { defined $ARG->{Moose_type} } @{$class->{attrs}} )
   {
      $get = "get_" . $attr->{name};
      $set = "set_" . $attr->{name};

      # Test accessors {{{2

      # Test valid values 
      foreach my $good_val ( @{$attr->{good}} )
      {
         $printable = defined $good_val ? $good_val : "undef";
         $obj = $class->{class}->new();
         lives_ok { $obj->$set( $good_val ) }
            "set_$attr->{name}( $printable ) succeeds";
         is( $obj->$get, $good_val, "get_$attr->{name} returns $printable" );
      }

      # Test invalid values 
      foreach my $bad_val ( @{$attr->{bad}} )
      {
         $printable = defined $bad_val ? $bad_val : "undef";
         $obj = $class->{class}->new();
         throws_ok { $obj->$set( $bad_val ) }
            qr/\($attr->{name}\) does not pass the type constraint/,
            "set_$attr->{name}( $printable ) dies";
         is( $obj->$get, undef, "get_$attr->{name} fails to undef" );
      }

      # Test initializers {{{2

      if ( $attr->{init} )
      {
         # Test valid values 
         foreach my $good_val ( @{$attr->{good}} )
         {
            $printable = defined $good_val ? $good_val : "undef";
            lives_ok {
                  $obj = $class->{class}->new( $attr->{name} => $good_val )
               }
               "new( $attr->{name} => $printable ) ($attr->{Moose_type}) runs";
            is( $obj->$get, $good_val, "new( $attr->{name} => $printable ) "
               . "works" );
         }

         # Test invalid values 
         foreach my $bad_val ( @{$attr->{bad}} )
         {
            $printable = defined $bad_val ? $bad_val : "undef";
            dies_ok { $class->{class}->new( $attr->{name} => $bad_val ) }
               "new( $attr->{name} => $printable ) ($attr->{Moose_type}) dies";
            throws_ok { $class->{class}->new( $attr->{name} => $bad_val ) }
               qr/\($attr->{name}\) does not pass the type constraint/,
               "new( $attr->{name} => $printable ) "
               . "throws an appropriate exception";
         }
      }
      else
      {
         # Test nothing does anything for init_arg => undef attrs 
         foreach my $val ( qw/ 1 foo /, undef )
         {
            $printable = defined $val ? $val : "undef";
            lives_ok { $obj = $class->{class}->new( $attr->{name} => $val ) }
               "new( $attr->{name} => $printable ) ($attr->{Moose_type}) runs";
            is( $obj->$get, undef, "get_$attr->{name} returns undef" );
         }
      }

      # }}}2
   }
}

# Function: test_entry_field_attributes {{{1
# Purpose:  Test the accessors for attributes corresponding to Gtk fields
# Input:    (hashref) {
#              class => class_name,
#              attrs => [
#                 name => attr_name, init => set from new()?,
#                 Gtk_type => Gtk2::Object desc., Moose_type => type,
#                 good => [ list of valid values ],
#                 bad => [ list of bad attrs ],
#              ] }
sub test_entry_field_attributes
{
   my $class = shift;
   my $obj = $class->{class}->new();
   
   foreach my $attr ( grep { defined $ARG->{Gtk_type} } @{$class->{attrs}} )
   {
      my $getter = "get_$attr->{name}_field";
      my $setter = "set_$attr->{name}_field";

      # Test accessors exist {{{2
      lives_ok { $obj->$getter } "Accessor to $attr->{name} exists";
      throws_ok { $obj->$setter } qr/Can't locate object method "$setter"/,
         "$attr->{name} is read-only";

      # Test attribute has correct type, and accessors work {{{2
      my $entry = $obj->$getter;

      # Test each element of a hashref
      if ( $attr->{Gtk_type} =~ /^HashRef/ )
      {
         foreach my $key ( keys $attr->{good}->[0] )
         {
            my ( $type ) = $attr->{Gtk_type} =~ /\[(.*)]/;
            isa_ok( $entry->{$key}, "Gtk2::$type",
               "$attr->{name} ($key) is a Gtk2::$type" );
            test_gtk_accessor( $entry->{$key}, $type,
               "$attr->{name} ($key)", $attr->{good}->[0]->{$key} );
         }
      }
      else
      {
         isa_ok( $obj->$getter, "Gtk2::$attr->{Gtk_type}", 
            "$attr->{name} is a Gtk2::$attr->{Gtk_type}" );
         test_gtk_accessor( $entry, $attr->{Gtk_type},
            $attr->{name}, $attr->{good}->[0] );
      }

      # }}}2
   }
}

# Function: test_gtk_accessor {{{2
sub test_gtk_accessor
{
   my $gtk_obj = shift; # Gtk object whose accessors are to be tested
   my $type = shift;    # Class the object belongs to (or use ref $gtk_obj)
   my $name = shift;    # Name of the attribute
   my $value = shift;   # Value to test with

   my $getter = $Gtk_types->{$type}->{getter};
   my $setter = $Gtk_types->{$type}->{setter};

   lives_ok { $gtk_obj->$setter( $value ) } "$name setter runs";
   lives_ok { $gtk_obj->$getter } "$name getter runs";
   is( $gtk_obj->$getter, $value, "$name accessors work" );
}
# }}}2

# Function: test_display_all {{{1
# Purpose:  Test the method display_all
# Input:    (hashref) {
#              class => class_name,
#              attrs => [
#                 name => attr_name, init => set from new()?,
#                 Gtk_type => Gtk2::Object desc., Moose_type => type,
#                 good => [ list of valid values ],
#                 bad => [ list of bad attrs ],
#              ] }
sub test_display_all
{
   my $class = shift;

   my $obj = $class->{class}->new();
   my $main_box = Gtk2::VBox->new();

   # display_all makes $box the root of an arbitrarily large tree
   lives_ok { $obj->display_all( box => $main_box ) } "display_all() runs";

   my @boxes_to_test = $main_box;
   my $found_fields; # Hash of Gtk types containing lists of matched fields

   # Iteratively search the children of every box in the tree for entries {{{2
   while ( @boxes_to_test )
   {
      my $box = shift @boxes_to_test;

      # Child boxes are added to a queue to be tested later;
      # Entry fields (of types in $Gtk_types) are added to a hash of lists to
      # be matched to their attribute
      foreach my $child ( $box->get_children() )
      {
         if ( $child->isa( "Gtk2::Box" ) )
         {
            push @boxes_to_test, $child;
         }
         else
         {
            my ( $type ) = grep { $child->isa( "Gtk2::$ARG" ) } keys %$Gtk_types;
            push @{$found_fields->{$type}}, $child if ( defined $type );
         }
      }
   }

   # Find the entry field corresponding to each entry attribute {{{2

   my @field_attrs = grep { defined $ARG->{Gtk_type} } @{$class->{attrs}};
   ATTR: foreach my $attr ( @field_attrs )
   {
      my $attr_get = "get_$attr->{name}_field";
      my $attr_field = $obj->$attr_get;

      # Find a match in the fields from the $main_box
      if ( $attr->{Gtk_type} =~ /^HashRef/ )
      {
         my ( $type ) = $attr->{Gtk_type} =~ /\[(.*)]/;
         foreach my $key ( keys $attr->{good}->[0] )
         {
            match_field_to_attr( $found_fields, $attr_field->{$key}, $type,
               "$attr->{name} ($key)" );
         }
      }
      else
      {
         match_field_to_attr( $found_fields, $attr_field, $attr->{Gtk_type},
            $attr->{name} );
      }
   }
   # }}}2
}

# match_field_to_attr {{{2
sub match_field_to_attr
{
   my $found_fields = shift;
   my $gtk_obj = shift;
   my $type = shift;
   my $name = shift;

   foreach my $field ( @{$found_fields->{$type}} )
   {
      defined $field or next;

      my $setter = $Gtk_types->{$type}->{setter};
      my $getter = $Gtk_types->{$type}->{getter};

      $field->$setter( 1 );
      if ( $gtk_obj->$getter eq 1 )
      {
         pass( "Entry field $name was displayed" );
         $field = undef;
         return 1;
      }
      else
      {
         $field->$setter( 0 );
      }

   }
   fail( "Entry field $name was not displayed" );
   return 0;
}

# }}}2

# Function: test_set_all {{{1
# Purpose:  Test the method set_all
# Input:    (hashref) {
#              class => class_name,
#              attrs => [ {
#                 name => attr_name, init => set from new()?,
#                 Gtk_type => Gtk2::Object desc., Moose_type => type,
#                 good => [ list of valid values ],
#                 bad => [ list of bad attrs ],
#                 } ] }
sub test_set_all
{
   my $class = shift;
   my @gtk_attrs = grep { defined $ARG->{Gtk_type} } @{$class->{attrs}};

   # Test set_all works with properly-set fields {{{2
   my $obj = $class->{class}->new();
   set_ancestor_fields( $obj, $class->{class} );
   set_field( $obj, $ARG, 'good' ) foreach ( @gtk_attrs );

   lives_ok { $obj->set_all() } "set_all runs";

   foreach my $attr ( @gtk_attrs )
   {
      my $get = "get_$attr->{name}";
      is_deeply( $obj->$get, $attr->{good}->[0],
         "$attr->{name} was set correctly" );
   }

   # Test set_all fails with improperly-set fields {{{2
   for my $i ( 0..(@gtk_attrs-1) )
   {
      # Make sure there is a failing value we can set to!
      @{$gtk_attrs[$i]->{bad}} or next;
      my @passing_attrs = grep { $ARG != $gtk_attrs[$i] } @gtk_attrs;

      # Set all attributes to passing values
      $obj = $class->{class}->new();
      set_ancestor_fields( $obj, $class->{class} );
      set_field( $obj, $ARG, 'good' ) foreach ( @passing_attrs );

      # Set one attribute to a value that will fail in Moose; this value must
      # pass Gtk's type-checking
      my $bad_attr = $gtk_attrs[$i];
      set_field( $obj, $bad_attr, 'bad' );

      # Test that set_all fails
      dies_ok { $obj->set_all() }
         "set_all fails with invalid $gtk_attrs[$i]->{name}";
   }
   # }}}2
}

# Function: set_ancestor_fields {{{2
# Purpose:  Set all Gtk fields of the class's ancestors to passing values
# Input:    (object) Vokab::Item::* object
#           (string) Full classname of the object
sub set_ancestor_fields
{
   my $obj = shift;
   my $classname = shift;

   my $parent = $classname =~ s/::\w*$//r;
   if ( $parent =~ /^Vokab::Item::.*/ )
   {
      set_ancestor_fields( $obj, $parent );
   }

   my $class_data = $data->{$parent};

   my @gtk_attrs = grep { defined $ARG->{Gtk_type} } @{$class_data->{attrs}};
   set_field( $obj, $ARG, 'good' ) foreach ( @gtk_attrs );
}

# Function: set_field {{{2
# Purpose:  Set a Gtk attribute, independent of whether it is a scalar or
#           hashref
# Input:    (Vokab::Item::*) object in which to set a Gtk attribute
#           (hashref): Data on an attribute
#           (scalar): Value to set the attribute to: good (true) or bad
#           (false)
sub set_field
{
   my $obj = shift;
   my $attr = shift;

   my $get = "get_$attr->{name}_field";
   my $field = $obj->$get;

   # Coerce value-to-set-to to something usable by $attr
   my $good = shift;
   if ( $good !~ /good|bad/ )
   {
      $good = $good ? "good" : "bad";
   }


   if ( $attr->{Gtk_type} =~ /^HashRef/ && ref $attr->{$good}->[0] eq "HASH" )
   {
      my ( $type ) = $attr->{Gtk_type} =~ /\[(.*)]/;
      my $set = $Gtk_types->{$type}->{setter};

      foreach my $key ( keys $attr->{$good}->[0] )
      {
         if ( defined $attr->{$good}->[0]->{$key} )
         {
            $field->{$key}->$set( $attr->{$good}->[0]->{$key} );
         }
      }
   }
   else
   {
      my $set = $Gtk_types->{$attr->{Gtk_type}}->{setter};
      $field->$set( $attr->{$good}->[0] );
   }
}

# }}}1

foreach my $class ( keys %$data )
{
   diag( $class );
   lives_ok { $class->new() } "$class->new() runs";
   isa_ok( $class->new(), $class, "$class->new() works" );

   test_attributes( $data->{$class} );             # Test raw attributes 
   test_entry_field_attributes( $data->{$class} ); # Test Gtk attributes
   test_display_all( $data->{$class} );           # Test Gtk attrs are drawn
   test_set_all( $data->{$class} );         # Raw attrs are set from Gtk attrs
}
