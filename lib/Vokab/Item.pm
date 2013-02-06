package Vokab::Item;

use strict;
use warnings;
use utf8;

# A Vokab::Item is meant to be used for any testable object.

use Moose;
use MooseX::FollowPBP; # use get_, set_ accessors
use namespace::autoclean; # clean up Moose droppings

has 'log' => ( is => 'ro',
               default => sub { return Log::Handler->get_logger("vokab"); },
               reader => 'log',   # override Moose::FollowPBP
               lazy => 1,         # don't set it until used
               init_arg => undef, # don't allow this to be set with new()
             );

has 'id' => ( is => 'ro' );
has 'type' => ( is => 'ro' );
has 'chapter' => ( is => 'ro' );
has 'section' => ( is => 'ro', isa => 'Vokab::Item::Word::Generic' );
has 'tests' => ( is => 'rw' );
has 'success' => ( is => 'rw' );
has 'score' => ( is => 'rw' );

__PACKAGE__->meta->make_immutable;

1;
