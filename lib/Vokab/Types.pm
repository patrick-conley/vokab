package Vokab::Types;

use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;
use 5.012;

use MooseX::Types -declare => [
   qw/ Natural IntBool Real Text OptText Gender Noun Verb EmptyStr/
];

use MooseX::Types::Moose qw/ Bool Int Num Str HashRef Undef/;

subtype( Natural, {
      as => Int,
      where => sub { $ARG >= 0 }
   }
);

subtype( IntBool, {
      as => Bool,
      where => sub { defined $ARG && ( $ARG == 0 || $ARG == 1 ) }
   }
);

subtype( Real, {
      as => Num,
      where => sub { $ARG >= 0 && $ARG <= 1 }
   }
);

subtype( Text, {
      as => Str,
      where => sub { $ARG =~ /^\w([-\w ']*[\w'])?$/u && $ARG !~ /[0-9]/ }
   }
);

subtype( EmptyStr, {
      as => Str,
      where => sub { $ARG eq "" }
   }
);

subtype( OptText, {
      as => Text | Undef | EmptyStr,
   }
);

subtype( Gender, {
      as => Str,
      where => sub { $ARG =~ /^[fmn]$/ }
   }
);

subtype( Noun, {
      as => Text,
      where => sub { $ARG !~ /^(the|der|die|das)\s/ }
   }
);

subtype( Verb, {
      as => HashRef[Noun],
      where => sub { 
         defined $ARG->{ich} && defined $ARG->{du}
            && ( defined $ARG->{er} || defined $ARG->{ihr} )
            && ( defined $ARG->{wir} || defined $ARG->{Sie} || defined $ARG->{sie} )
      }
   }
);

