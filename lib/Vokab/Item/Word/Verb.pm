package Vokab::Item::Word::Verb;

use strict;
use warnings;
use utf8;

use Moose;
extends 'Vokab::Item::Word';

has 'person' => ( is => 'ro' );

# A Vokab::Item::Word::Verb is a *conjugated* verb. When entering a new item,
# each person must be entered, but in selecting a verb only one person is
# given.

__PACKAGE__->meta->make_immutable;

1;
