package Vokab::Types::Test;

use strict;
use warnings;
use English qw/ -no-match-vars/;
use utf8;

use Vokab::Types qw/ Natural IntBool Real Text OptText Gender Noun Verb Section/;

use Moose;
use MooseX::FollowPBP;
use namespace::autoclean;

has( Natural => ( is => 'rw', isa => Natural, predicate => "has_Natural" ) );
has( IntBool => ( is => 'rw', isa => IntBool, predicate => "has_IntBool" ) );
has( Real => ( is => 'rw', isa => Real, predicate => "has_Real" ) );
has( Text => ( is => 'rw', isa => Text, predicate => "has_Text" ) );
has( OptText => ( is => 'rw', isa => OptText, predicate => "has_OptText" ) );
has( Gender => ( is => 'rw', isa => Gender, predicate => "has_Gender" ) );
has( Noun => ( is => 'rw', isa => Noun, predicate => "has_Noun" ) );
has( Verb => ( is => 'rw', isa => Verb, predicate => "has_Verb" ) );
has( Section => ( is => 'rw', isa => Section, predicate => "has_Section" ) );

__PACKAGE__->meta->make_immutable;

1;
