use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;

use Data::Dumper;
local $Data::Dumper::Indent = 0;
local $Data::Dumper::Varname = '';
local $Data::Dumper::Terse = 1;
local $Data::Dumper::Pad = " ";

use Test::Most tests => 223;

# Note: this test script relies on the Moose class Vokab::Types::Test, not
# Vokab::Types (which is what's actually being tested). This is so I have a
# place to declare a class and attributes which use the custom types.
# Vokab::Types::Test must be maintained manually unless I write some further
# maintenance script.

BEGIN # [1]
{
   bail_on_fail();
   use_ok( "Vokab::Types::Test" );
   restore_fail();
}

my $obj = undef;

# [59*3]
my @type_tests = (
   # attr/type     good values            bad values
   [ 'Natural',
      [ 0, 56 ], # [2]
      [ -3, 0.1, undef, 'a', 'The word' ] ], # [5]
   [ 'IntBool',
      [ 0, 1 ], # [2]
      [ -1, 0.5, undef, 'a', 'The word' ] ], # [5]
   [ 'Real',
      [ 0, 1, 0.001, 0.58 ], # [4]
      [ -0.01, 1.01, 55, undef, 'a', 'The word' ] ], # [6]
   [ 'Text',
      [ 'a', 'The word', 'word 1', '& things' ], # [4]
      [ undef, '1', '-', "" ] ], # [4]
   [ 'OptText',
      [ 'a', 'The word', 'word 1', '& things', undef, "" ], # [6]
      [ '1', '-' ] ], # [2]
   [ 'Gender',
      [ 'm', 'n', 'f', 'masculine' ], # [4]
      [ 'a', 'The word', undef, 2, "" ] ], # [5]
   [ 'Noun',
      [ 'a', 'word', 'Übersetzungen' ], # [3]
      [ 'the word', 'das Wort', 'die Wörter', '1', 'Word 1', undef, "" ] ], # [7]
   [ 'Verb',
      [ { ich => 'bin', du => 'bist', er => 'ist', Sie => 'sind',
            wir => 'sind', ihr => 'seid', sie => 'sind' },
        { ich => 'gehe', du => 'gehst', er => 'geht', wir => 'gehen' },
        { ich => 'rufe an', du => 'rufst an', er => 'ruft an', wir => 'rufen an' },
        { ich => 'rufe an', du => 'rufst an', ihr => 'ruft an', wir => 'rufen an' },
        { ich => 'rufe an', du => 'rufst an', ihr => 'ruft an', Sie => 'rufen an' },
        # TODO: Must test wir/sie/Sie <= infinitive separately
      ], # [5]
      [ 'a', 'bin', 1, undef, "",
        { ich => 'gehe', du => 'gehst 1', er => 'geht', wir => 'gehen' },
        { ich => 'rufe an', du => 'rufst an', wir => 'rufen an' },
        { ich => 'rufe an', du => 'rufst an', er => 'ruft an' },
        { ich => 'rufe an', er => 'ruft an', wir => 'rufen an' },
        { du => 'rufst an', er => 'ruft an', wir => 'rufen an' },
      ] # [10]
   ]
);

# [3] per input value
foreach my $type ( @type_tests )
{
   my $getter    = "get_" . $type->[0];
   my $setter    = "set_" . $type->[0];
   my $predicate = "has_" . $type->[0];

   foreach my $value ( @{$type->[1]} )
   {
      $obj = Vokab::Types::Test->new();
      my $printable = defined $value ? Data::Dumper::Dumper( $value ) : "undef";
      lives_ok { $obj->$setter( $value ) } "(valid input) set_$type->[0]( $printable ) succeeds";
      ok( $obj->$predicate, "(valid input) $type->[0] has been set" );
      is( $obj->$getter, $value, "(valid input) get_$type->[0] returns $printable" );
   }

   foreach my $value ( @{$type->[2]} )
   {
      $obj = Vokab::Types::Test->new();
      my $printable = defined $value ? Data::Dumper::Dumper( $value ) : "undef";
      throws_ok { $obj->$setter( $value ) }
         qr/\($type->[0]\) does not pass the type constraint/,
         "(invalid input) set->$type->[0]( $printable ) fails";
      ok( ! $obj->$predicate, "(invalid input) $type->[0] has not been set" );
      is( $obj->$getter, undef, "(invalid input) get_$type->[0] returns nothing" );
   }
}
