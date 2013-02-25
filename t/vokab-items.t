use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;

use Test::Most tests => 216;
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
               "$class->new( $attr->{attr} => $printable )  ($attr->{type}) succeeds";
            is( $item->$get, $good_val, "new( $attr->{attr} => $printable ) works" );
         }

         # Test invalid values [bad]
         foreach my $bad_val ( @{$attr->{bad}} )
         {
            $printable = defined $bad_val ? $bad_val : "undef";
            throws_ok { $class->new( $attr->{attr} => $bad_val ) }
               qr/\($attr->{attr}\) does not pass the type constraint/,
               "$class->new( $attr->{attr} => $printable ) ($attr->{type}) dies";
         }
      }
      else
      {
         # Test nothing does anything for init_arg => undef attrs [2*3]
         foreach my $val ( qw/ 1 foo /, undef )
         {
            $printable = defined $val ? $val : "undef";
            lives_ok { $item = $class->new( $attr->{attr} => $val ) }
               "$class->new( $attr->{attr} => $printable ) ($attr->{type}) succeeds";
            is( $item->$get, undef, "get_$attr->{attr} returns undef" );
         }
      }
   }
}

# }}}1

# tests = init*(4*good+3*bad)+noinit*(6+2*good+2*bad)
# Vokab::Item [21+30+42=93] {{{1
my @item_attrs = (
   # attr         type        init  good              bad...
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

# }}}1

run_tests( 'Vokab::Item', @item_attrs );
run_tests( 'Vokab::Item::Word', @word_attrs );
run_tests( 'Vokab::Item::Word::Noun', @noun_attrs );
run_tests( 'Vokab::Item::Word::Verb', @verb_attrs );

