package Vokab::Types;

use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;

use MooseX::Types -declare => [
   qw/ Natural IntBool Real Text OptText Gender Noun/
];

use MooseX::Types::Moose qw/ Bool Int Num Str Any/;

subtype Natural,
   as Int,
   where { $ARG >= 0 };

subtype IntBool,
   as Bool,
   where { defined $ARG && ( $ARG == 0 || $ARG == 1 ) };

subtype Real,
   as Num,
   where { $ARG >= 0 && $ARG <= 1 };

subtype Text,
   as Str,
   where { $ARG =~ /[a-zA-Z]/ };

subtype OptText,
   as Any,
   where { (! defined $ARG) || $ARG =~ /[a-zA-Z]/ || $ARG =~ /^$/ };

subtype Gender,
	as Str,
	where { $ARG =~ /^[fmn]/ };

subtype Noun,
   as Text,
   where { $ARG !~ /^\s*(the|der|die|das)/ && $ARG !~ /[0-9]/ };

