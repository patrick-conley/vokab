use strict;
use warnings;
use English qw/ -no-match-vars /;
use utf8;

use Test::Most tests => 320;
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
my $data = [
   {
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
            bad => [ -1, 'foo' ]
         },
         {
            name => 'section', init => 1,
            Gtk_type => "Entry", Moose_type => 'OptText',
            good => [ 'foo', '' ],
            bad => [ 1 ]
         },
      ],
   },
   {
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
   {
      class => 'Vokab::Item::Word::Noun',
      attrs => [
         {
            name => 'gender', init => 0,
            Gtk_type => "Entry", Moose_type => 'Gender',
            good => [ 'm', 'f', 'n' ],
            bad => [ undef, 1, 'a', 'e' ]
         },
         {
            name => 'display_gender', init => 0,
            Gtk_type => "CheckButton", Moose_type => 'Bool',
            good => [ '', 1 ],
            bad => [ 'foo', -1, ]
         },
         {
            name => 'en', init => 0,
            Moose_type => 'Noun',
            good => [ 'foo' ],
            bad => [ 1, 'the foo', undef ]
         }, 
         {
            name => 'de', init => 0,
            Moose_type => 'Noun',
            good => [ 'bar' ],
            bad => [ 1, 'der bar', 'die bar', 'das bar', undef ]
         }, 
      ],
   },
   {
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
   {
      class => 'Vokab::Item::Word::Generic',
      attrs => [],
   },
];
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
            $class->{class} . "->set_$attr->{name}( $printable ) succeeds";
         is( $obj->$get, $good_val, "get_$attr->{name} returns $printable" );
      }

      # Test invalid values 
      foreach my $bad_val ( @{$attr->{bad}} )
      {
         $printable = defined $bad_val ? $bad_val : "undef";
         $obj = $class->{class}->new();
         throws_ok { $obj->$set( $bad_val ) }
            qr/\($attr->{name}\) does not pass the type constraint/,
            $class->{class} . "->set_$attr->{name}( $printable ) dies";
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
               "$class->{class}->new( $attr->{name} => $printable ) "
               . " ($attr->{Moose_type}) runs";
            is( $obj->$get, $good_val, "new( $attr->{name} => $printable ) "
               . "works" );
         }

         # Test invalid values 
         foreach my $bad_val ( @{$attr->{bad}} )
         {
            $printable = defined $bad_val ? $bad_val : "undef";
            dies_ok { $class->{class}->new( $attr->{name} => $bad_val ) }
               $class->{class} . "->new( $attr->{name} => $printable ) "
               . "($attr->{Moose_type}) dies";
            throws_ok { $class->{class}->new( $attr->{name} => $bad_val ) }
               qr/\($attr->{name}\) does not pass the type constraint/,
               $class->{class} .  "->new( $attr->{name} => $printable ) "
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
               "$class->{class}->new( $attr->{name} => $printable ) " .
               "($attr->{Moose_type}) runs";
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

# Function: test_display_all {{{1
# Purpose:  Test the method display_all
# Tests:    ??
# Input:    (string) The class name
#           (hashref) datatype of each attribute
#           (hashref) some information about each datatype
sub test_display_all
{
   my $class = shift;

   my $obj = $class->{class}->new();
   my $main_box = Gtk2::VBox->new();

   # display_all makes $box the root of an arbitrarily large tree
   lives_ok { $obj->display_all( box => $main_box ) }
      "$class->{class}->new runs";

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
         foreach my $key ( keys $attr->{good}->[0] )
         {
            my ( $type ) = $attr->{Gtk_type} =~ /\[(.*)]/;
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

# }}}1

foreach my $class ( @$data )
{
   my $name = $class->{class};
   lives_ok { $name->new() } "$name->new() runs";
   isa_ok( $name->new(), $name, "$name->new() works" );

   test_attributes( $class );
   test_entry_field_attributes( $class );
   test_display_all( $class );
}
