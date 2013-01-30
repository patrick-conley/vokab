package Vokab::Item::Word::Noun;

use strict;
use warnings;
use utf8;

# A Vokab::Item::Word::Noun is a noun. It will ordinarilly have a specified
# gender, and the translation must include the correct pronoun. The plural
# form must also be entered. Certain words (eg., "friend") may allow both the
# masculine and feminine, in which case both must be correctly given.

use Moose;
extends 'Vokab::Item::Word';

has 'gender' => ( is => 'ro' );
has 'plural' => ( is => 'ro' );

__PACKAGE__->meta->make_immutable;

1;
