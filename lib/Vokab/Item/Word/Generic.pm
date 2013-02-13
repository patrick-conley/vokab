package Vokab::Item::Word::Generic;

use strict;
use warnings;
use utf8;

# A Vokab::Item::Word::Generic is meant to capture words with no special
# properties. It doesn't correspond to a DB table

use Moose;
extends 'Vokab::Item::Word';

__PACKAGE__->meta->make_immutable;

1;
