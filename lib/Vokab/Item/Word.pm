package Vokab::Item::Word;

use strict;
use warnings;
use utf8;

# A Vokab::Item::Word is a testable object requiring a literal translation of
# English to Deutsch (although in some cases, a regex may be used to identify
# correct results if the word is ambiguous, eg. "welcome" to "Wilkommen" or
# "herzlich Wilkommen").

use Moose;
extends 'Vokab::Item';

has 'en' => ( is => 'ro', required => 1 );
has 'de' => ( is => 'ro' );
has 'match' => ( is => 'ro' );

__PACKAGE__->meta->make_immutable;

1;
