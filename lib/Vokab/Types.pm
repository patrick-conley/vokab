package Vokab::Types;

use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;

use MooseX::Types -declare => [
   qw/ Natural IntBool Real Text OptText Gender Noun Verb/
];

use MooseX::Types::Moose qw/ Bool Int Num Str Any HashRef/;

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
      where => sub { $ARG =~ /[a-zA-Z]/ }
   }
);

subtype( OptText, {
      as => Any,
      where => sub { (! defined $ARG) || $ARG =~ /[a-zA-Z]/ || $ARG =~ /^$/ }
   }
);

subtype( Gender, {
      as => Str,
      where => sub { $ARG =~ /^[fmn]/ }
   }
);

subtype( Noun, {
      as => Text,
      where => sub { $ARG !~ /^\s*(the|der|die|das)\s/ && $ARG !~ /[0-9]/ }
   }
);

subtype( Verb, {
      # FIXME: should use a specific 'Word' type, allowing alpha characters
      # and things like apostrophes or hyphens, but not numbers
      as => HashRef[Noun],
      where => sub { 
         defined $ARG->{ich} && defined $ARG->{du}
            && ( defined $ARG->{er} || defined $ARG->{ihr} )
            && ( defined $ARG->{wir} || defined $ARG->{Sie} || defined $ARG->{sie} )
      }
   }
);

