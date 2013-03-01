use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;

use Test::Most tests => 332;
use Data::Dumper;
use Gtk2 '-init';

BEGIN # [5]
{
   die_on_fail();
   use_ok( "Vokab::Item" );
   use_ok( "Vokab::Item::Word" );
   use_ok( "Vokab::Item::Word::Noun" );
   use_ok( "Vokab::Item::Word::Verb" );
   use_ok( "Vokab::Item::Word::Generic" );
   restore_fail();
}

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

my @classes = (
   'Vokab::Item',
   'Vokab::Item::Word',
   'Vokab::Item::Word::Noun',
   'Vokab::Item::Word::Verb',
   'Vokab::Item::Word::Generic',
);

# [classes*2=10]
foreach my $class ( @classes )
{
   lives_ok { $class->new() } "$class->new() runs";
   isa_ok( $class->new(), $class, "$class->new() works" );
}

# Function: test_attributes {{{1
# Purpose:  Test class initializers and accessors.
# Tests:    good   = number of valid values
#           bad    = number of invalid values
#           init   = number of attrs with init_arg != undef
#           noinit = number of attrs with init_arg == undef
#           tests = init*(4*good+3*bad)+noinit*(6+2*good+2*bad)
# Input:    (string) The class name;
#           (list) List of lists of attributes. Each attribute has keys
#           'attr', 'type', 'init', 'good', 'bad'. 'attr' is the attribute
#           name, 'init' is whether the attribute can be set in new(), 'good'
#           and 'bad' are lists of good/bad values to test.
#           If the attribute can't be initialized from new(), Moose accepts
#           and ignores any input.
sub test_attributes
{
   my $class = shift;
   my @attrs = @ARG;

   my $item;
   my ( $get, $set );
   my $printable;

   # [init*(4*good+3*bad)+noinit*(6+2*good+2*bad)]
   foreach my $attr ( @attrs )
   {
      $get = "get_" . $attr->{attr};
      $set = "set_" . $attr->{attr};

      # Test accessors {{{2

      # Test valid values [2*good]
      foreach my $good_val ( @{$attr->{good}} )
      {
         $printable = defined $good_val ? $good_val : "undef";
         $item = $class->new();
         lives_ok { $item->$set( $good_val ) }
            "set_$attr->{attr}( $printable ) succeeds";
         is( $item->$get, $good_val, "get_$attr->{attr} returns $printable" );
      }

      # Test invalid values [2*bad]
      foreach my $bad_val ( @{$attr->{bad}} )
      {
         $printable = defined $bad_val ? $bad_val : "undef";
         $item = $class->new();
         throws_ok { $item->$set( $bad_val ) }
            qr/\($attr->{attr}\) does not pass the type constraint/,
            "$class->set_$attr->{attr}( $printable ) dies";
         is( $item->$get, undef, "$class->get_$attr->{attr} fails to undef" );
      }

      # Test initializers {{{2

      if ( $attr->{init} )
      {
         # Test valid values [2*good]
         foreach my $good_val ( @{$attr->{good}} )
         {
            $printable = defined $good_val ? $good_val : "undef";
            lives_ok { $item = $class->new( $attr->{attr} => $good_val ) }
               "$class->new( $attr->{attr} => $printable )  ($attr->{type}) "
               . "runs";
            is( $item->$get, $good_val, "new( $attr->{attr} => $printable ) "
               . "works" );
         }

         # Test invalid values [2*bad]
         foreach my $bad_val ( @{$attr->{bad}} )
         {
            $printable = defined $bad_val ? $bad_val : "undef";
            dies_ok { $class->new( $attr->{attr} => $bad_val ) }
               "$class->new( $attr->{attr} => $printable ) ($attr->{type}) "
               . "dies";
            throws_ok { $class->new( $attr->{attr} => $bad_val ) }
               qr/\($attr->{attr}\) does not pass the type constraint/,
               "$class->new( $attr->{attr} => $printable ) throws an "
               . "appropriate exception";
         }
      }
      else
      {
         # Test nothing does anything for init_arg => undef attrs [2*3]
         foreach my $val ( qw/ 1 foo /, undef )
         {
            $printable = defined $val ? $val : "undef";
            lives_ok { $item = $class->new( $attr->{attr} => $val ) }
               "$class->new( $attr->{attr} => $printable ) ($attr->{type}) "
               . "runs";
            is( $item->$get, undef, "get_$attr->{attr} returns undef" );
         }
      }

      # }}}2
   }
}

# Function: test_entry_field_attributes {{{1
# Purpose:  Test the accessors for attributes corresponding to Gtk fields
# Tests:    ??
# Input:    (hashref):
#              {
#                 class => '',
#                 attrs => [
#                    { name => '', Gtk type => '', value => '' }
#                    # or
#                    { name => 'field', Gtk type => '', keys => [], value => [] }
#                 ]
#              }
sub test_entry_field_attributes
{
   my $class = shift;

   my $obj = $class->{class}->new();
   
   foreach my $attr ( @{$class->{attrs}} )
   {
      my $getter = "get_$attr->{name}_field";
      my $setter = "set_$attr->{name}_field";

      # Test accessors exist {{{2
      lives_ok { $obj->$getter } "Accessor to $attr->{name} exists";
      throws_ok { $obj->$setter } qr/Can't locate object method "$setter"/,
         "$attr->{name} is read-only";

      # Test the attribute has been built to the correct type {{{2
      isa_ok( $obj->$getter, "Gtk2::$attr->{type}", 
         "$attr->{name} is a Gtk2::$attr->{type}" );

      # Test accessors {{{2
      my $entry = $obj->$getter;
      my $entry_set = $Gtk_types->{$attr->{type}}->{setter};
      my $entry_get = $Gtk_types->{$attr->{type}}->{getter};

      lives_ok { $entry->$entry_set( $attr->{value} ) }
         "$attr->{name} setter runs";
      lives_ok { $entry->$entry_get }
         "$attr->{name} getter runs";
      is( $entry->$entry_get, $attr->{value},
         "$attr->{name} accessors work" );
      # }}}2
   }
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
   my %found_fields; # Hash of Gtk types containing lists of matched fields

   # Iteratively search the children of every box in the tree for entries {{{2
   foreach my $box ( @boxes_to_test )
   {
      foreach my $child ( $box->get_children() )
      {
         if ( $child->isa( "Gtk2::Box" ) )
         {
            # Further boxes should be added to the main list to be tested
            # later

            push @boxes_to_test, $child;
         }
         else
         {
            my ( $type ) = grep { $child->isa( "Gtk2::$ARG" ) } keys %$Gtk_types;
            if ( defined $type )
            {
               push @{$found_fields{$type}}, $child;
            }
         }
      }
   }

   # Find the entry field corresponding to each entry attribute {{{2

   ATTR: foreach my $attr ( @{$class->{attrs}} )
   {
      my $attr_get = "get_$attr->{name}_field";
      my $attr_field = $obj->$attr_get;

      # Test each field foreach
      foreach my $field ( @{$found_fields{$attr->{type}}} )
      {
         defined $field or next;

         my $setter = $Gtk_types->{$attr->{type}}->{setter};
         my $getter = $Gtk_types->{$attr->{type}}->{getter};

         $field->$setter( 1 );
         if ( $attr_field->$getter eq 1 )
         {
            pass( "Entry field $attr->{name} was displayed" );
            $field = undef;
            next ATTR;
         }
         else
         {
            $field->$setter( 0 );
         }

      }
      fail( "Entry field $attr->{name} was not displayed" );
   }

   # }}}2

}

# }}}1

# tests = init: 4*(good+bad)
#         noinit: 2*(good+bad) + 3*#attrs
# Vokab::Item [24+30+42=93] {{{1
my @item_attrs = (
   {
      attr => 'id',
      type => 'Natural',
      init => 0,
      good => [ 1, 35 ],
      bad => [ -1, 'foo' ]
   }, 
   {
      attr => 'class',
      type => 'ClassName',
      init => 0,
      good => [ 'Vokab::Item::Word::Noun' ],
      bad => [ 'foo', 'Vokab::Item::Foo' ]
   }, 
   {
      attr => 'tests',
      type => 'Natural',
      init => 0,
      good => [ 0, 1 ],
      bad => [ -1, 'foo' ]
   }, 
   {
      attr => 'success',
      type => 'Natural',
      init => 0,
      good => [ 0, 1 ],
      bad => [ -1, 'foo' ]
   }, 
   {
      attr => 'score',
      type => 'Real',
      init => 0,
      good => [ 0, 1, 0.8 ],
      bad => [ -0.1, 1.1, 'foo' ]
   }, 
   {
      attr => 'chapter',
      type => 'Natural',
      init => 1,
      good => [ 1 ],
      bad => [ -1, 'foo' ]
   }, 
   {
      attr => 'section',
      type => 'OptText',
      init => 1,
      good => [ 'foo', undef ],
      bad => [ 1 ]
   }, 
);

# Vokab::Item::Word [18+18=40] {{{1
my @word_attrs = (
   {
      attr => 'en',
      type => 'Text',
      init => 0,
      good => [ 'foo', 'the foo' ],
      bad => [ 1, undef ]
   }, 
   {
      attr => 'de',
      type => 'Text',
      init => 0,
      good => [ 'bar', 'der bar' ],
      bad => [ 1, undef ]
   }, 
   {
      attr => 'alternate',
      type => 'OptText',
      init => 0,
      good => [ undef ],
      bad => []
   }, 
);

# Vokab::Item::Word::Noun [24+44=36] {{{1
my @noun_attrs = (
   {
      attr => 'gender',
      type => 'Gender',
      init => 0,
      good => [ 'm', 'f', 'n' ],
      bad => [ undef, 1, 'a', 'e' ]
   }, 
   {
      attr => 'display_gender',
      type => 'IntBool',
      init => 0,
      good => [ 0, 1 ],
      bad => [ 'foo', -1, undef ]
   }, 
   {
      attr => 'en',
      type => 'Noun',
      init => 0,
      good => [ 'foo' ],
      bad => [ 1, 'the foo', undef ]
   }, 
   {
      attr => 'de',
      type => 'Noun',
      init => 0,
      good => [ 'bar' ],
      bad => [ 1, 'der bar', 'die bar', 'das bar', undef ]
   }, 
);

# Vokab::Item::Word::Verb [6+8=14] {{{1
my @verb_attrs = (
   {
      attr => 'conjugation',
      type => 'Verb',
      init => 0,
      good => [
         { ich => 'foo', du => 'foo', er => 'foo', Sie => 'foo',
            wir => 'foo', ihr => 'foo', sie => 'foo' }
      ],
      bad => [ { wir => 'foo' }, undef, "" ],
   }, 
);

# Vokab::Item::Word::Generic [0] {{{1
my @generic_attrs = ();

# }}}1

test_attributes( 'Vokab::Item', @item_attrs );
test_attributes( 'Vokab::Item::Word', @word_attrs );
test_attributes( 'Vokab::Item::Word::Noun', @noun_attrs );
test_attributes( 'Vokab::Item::Word::Verb', @verb_attrs );
test_attributes( 'Vokab::Item::Word::Generic', @generic_attrs );

# Data on entry attributes {{{1
my $entry_data = [
   {
      class => 'Vokab::Item',
      attrs => [
         { name => 'chapter', type => "SpinButton", value => 3 },
         { name => 'section', type => "Entry", value => "a", },
      ],
   },
   {
      class => 'Vokab::Item::Word',
      attrs => [
         { name => 'en', type => "Entry", value => "b", },
         { name => 'de', type => "Entry", value => "c", },
         { name => 'alternate', type => "Entry", value => "d", },
      ],
   },
   {
      class => 'Vokab::Item::Word::Noun',
      attrs => [
         { name => 'gender', type => "Entry", value => "f" },
         { name => 'display_gender', type => "CheckButton", value => 1 },
      ],
   },
   {
      class => 'Vokab::Item::Word::Verb',
      attrs => [
         { name => 'ich', type => "Entry", value => 'z', },
         { name =>  'du', type => "Entry", value => 'y', },
         { name =>  'er', type => "Entry", value => 'x', },
         { name => 'Sie', type => "Entry", value => 'w', },
         { name => 'wir', type => "Entry", value => 'v', },
         { name => 'ihr', type => "Entry", value => 'u', },
         { name => 'sie', type => "Entry", value => 't', },
      ],
   },
   {
      class => 'Vokab::Item::Word::Generic',
      attrs => [],
   },
];
# }}}1

foreach my $class ( @$entry_data )
{
   test_entry_field_attributes( $class );
   test_display_all( $class );
}
