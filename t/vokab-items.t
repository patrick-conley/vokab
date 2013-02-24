use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;

use Test::Most tests => 202;
use File::Temp;

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

# Function: run_tests {{{1
# Purpose:  Test class initializers and accessors.
# Tests:    good   = number of valid values
#           bad    = number of invalid values
#           init   = number of attrs with init_arg != undef
#           noinit = number of attrs with init_arg == undef
#           tests = init*(4*good+3*bad)+noinit*(6+2*good+2*bad)
# Input:    (string) The class name;
#           (list) List of lists of attributes. Each attribute has name, type,
#           a bool indicating whether it can be set in new(), an array of
#           valid values, and an array of invalid values. If the attribute
#           can't be initialized from new(), Moose accepts any input, and
#           ignores it.
sub run_tests
{
   my $class = shift;
   my @attrs = @ARG;

   my $item;
   my ( $get, $set );
   my $printable;

   # [init*(4*good+3*bad)+noinit*(6+2*good+2*bad)]
   foreach my $attr ( @attrs )
   {
      $get = "get_" . $attr->[0];
      $set = "set_" . $attr->[0];

      # Test accessors

      # Test valid values [2*good]
      foreach my $good_val ( @{$attr->[3]} )
      {
         $printable = defined $good_val ? $good_val : "undef";
         $item = $class->new();
         lives_ok { $item->$set( $good_val ) }
            "set_$attr->[0]( $printable ) succeeds";
         is( $item->$get, $good_val, "get_$attr->[0] returns $printable" );
      }

      # Test invalid values [2*bad]
      foreach my $bad_val ( @{$attr->[4]} )
      {
         $printable = defined $bad_val ? $bad_val : "undef";
         $item = $class->new();
         throws_ok { $item->$set( $bad_val ) }
            qr/\($attr->[0]\) does not pass the type constraint/,
            "$class->set_$attr->[0]( $printable ) dies";
         is( $item->$get, undef, "$class->get_$attr->[0] fails to undef" );
      }

      # Test initializers

      if ( $attr->[2] )
      {
         # Test valid values [2*good]
         foreach my $good_val ( @{$attr->[3]} )
         {
            $printable = defined $good_val ? $good_val : "undef";
            lives_ok { $item = $class->new( $attr->[0] => $good_val ) }
               "$class->new( $attr->[0] => $printable )  ($attr->[1]) succeeds";
            is( $item->$get, $good_val, "new( $attr->[0] => $printable ) works" );
         }

         # Test invalid values [bad]
         foreach my $bad_val ( @{$attr->[4]} )
         {
            $printable = defined $bad_val ? $bad_val : "undef";
            throws_ok { $class->new( $attr->[0] => $bad_val ) }
               qr/\($attr->[0]\) does not pass the type constraint/,
               "$class->new( $attr->[0] => $printable ) ($attr->[1]) dies";
         }
      }
      else
      {
         # Test nothing does anything for init_arg => undef attrs [2*3]
         foreach my $val ( qw/ 1 foo /, undef )
         {
            $printable = defined $val ? $val : "undef";
            lives_ok { $item = $class->new( $attr->[0] => $val ) }
               "$class->new( $attr->[0] => $printable ) ($attr->[1]) succeeds";
            is( $item->$get, undef, "get_$attr->[0] returns undef" );
         }
      }
   }
}

# }}}1

# tests = init*(4*good+3*bad)+noinit*(6+2*good+2*bad)

# Vokab::Item [21+30+42=93]
my @item_attrs = (
   # attr         type        init  good              bad...
   [ 'id',        'NotNegative',         0, [ 1, 35 ],        [ -1, 'foo' ] ],
   [ 'class',     'ClassName',   0, [ 'Vokab::Item::Word::Noun' ], [ 'foo', 'Vokab::Item::Foo' ] ],
   [ 'tests',     'NotNegative', 0, [ 0, 1 ],         [ -1, 'foo' ] ],
   [ 'success',   'NotNegative', 0, [ 0, 1 ],         [ -1, 'foo' ] ],
   [ 'score',     'Real',        0, [ 0, 1, 0.8 ],    [ -0.1, 1.1, 'foo' ] ],
   [ 'chapter',   'NotNegative', 1, [ 1 ],            [ -1, 'foo' ] ],
   [ 'section',   'OptText',        1, [ 'foo', undef ], [ 1 ]   ],
);

# Vokab::Item::Word [18+18=40]
my @word_attrs = (
   [ 'en',        'Text', 0, [ 'foo', 'the foo' ], [ 1, undef ] ],
   [ 'de',        'Text', 0, [ 'bar', 'der bar' ], [ 1, undef ] ],
   [ 'alternate', 'OptText', 0, [ undef ], [] ],
);

# Vokab::Item::Word::Noun [24+44=36]
my @noun_attrs = (
   [ 'gender',          'Str', 0, [ 'm', 'f', 'n' ],  [ undef, 1, 'a', 'e' ] ],
   [ 'display_gender',  'Int', 0, [ 0, 1 ],           [ 'foo', -1, undef ] ],
   [ 'en',              'Str', 0, [ 'foo' ],          [ 1, 'the foo', undef ] ],
   [ 'de',              'Str', 0, [ 'bar' ],          [ 1, 'der bar', 'die bar', 'das bar', undef ] ],
);

run_tests( 'Vokab::Item', @item_attrs );
run_tests( 'Vokab::Item::Word', @word_attrs );
run_tests( 'Vokab::Item::Word::Noun', @noun_attrs );

