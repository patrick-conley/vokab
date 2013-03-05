package Vokab::Types;

use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;
use 5.012;

use MooseX::Types -declare => [
   qw/ Natural IntBool Real Text OptText Gender Noun Verb EmptyStr/
];

use MooseX::Types::Moose qw/ Bool Int Num Str HashRef /;
use Data::Dumper;

subtype( Natural, {
      as => Int,
      where => sub { $ARG >= 0 },
      message => sub { $ARG = defined $ARG ? $ARG : "undef";
         return "'$ARG' is not a valid natural number.\n" }
   }
);

subtype( IntBool, { # NB: currently unused
      as => Bool,
      where => sub { defined $ARG && ( $ARG == 0 || $ARG == 1 ) },
   }
);

subtype( Real, {
      as => Num,
      where => sub { $ARG >= 0 && $ARG <= 1 },
      message => sub { $ARG = defined $ARG ? $ARG : "undef";
         return "'$ARG' is not a valid real number. Value must be [0,1].\n" }
   }
);

subtype( Text, {
      as => Str,
      where => sub { $ARG =~ /^\w([-\w ']*[\w'])?$/u && $ARG !~ /[0-9]/ },
      message => sub { $ARG = defined $ARG ? $ARG : "undef";
         return "'$ARG' is not valid Text."
            . " Field may contain letters, apostrophes, dashes.\n" },
   }
);

subtype( EmptyStr, {
      as => Str,
      where => sub { $ARG eq "" },
   }
);

subtype( OptText, {
      as => Text | EmptyStr,
   }
);

subtype( Gender, {
      as => Str,
      where => sub { $ARG =~ /^[fmn]$/ },
      message => sub { $ARG = defined $ARG ? $ARG : "undef";
         return "'$ARG' is not a gender."
            . " Value must be (m)asculine, (f)eminine, or (n)euter.\n" }
   }
);

subtype( Noun, {
      as => Text,
      where => sub { $ARG !~ /^(the|der|die|das)\s/ },
      message => sub { $ARG = defined $ARG ? $ARG : "undef";
         return "'$ARG' is not a valid Noun. Do not include an article.\n" }
   }
);

subtype( Verb, {
      as => HashRef[Noun],
      where => sub { 
         defined $ARG->{ich} && defined $ARG->{du}
            && ( defined $ARG->{er} || defined $ARG->{ihr} )
            && ( defined $ARG->{wir} || defined $ARG->{Sie} || defined $ARG->{sie} )
      },
      message => sub { Data::Dumper::Dumper( $ARG )
         . " is not a valid Verb.\n" }
   }
);

