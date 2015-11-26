Warning: this project is abandoned and probably non-functional.

# Name

vokab: A study tool for German vocabulary, using weighted (random?) selection
of words.

# Installation

Installation is simple, but picky. Clone the repository with

    git clone git@github.com:patrick-conley/vokab.git

and run the program `vokab/bin/vokab` The executable may be _symlinked_
elsewhere for convenience.

## Dependencies

This program depends on the following Perl packages from CPAN:

    Log::Handler
    Term::ReadKey
    Moose
    MooseX::FollowPBP
    Getopt::Long
    Pod::Usage
    Gtk2

along with the module `PConley::Log::Setup`, from
[https://github.com/patrick-conley/Log-Handler-setup](https://github.com/patrick-conley/Log-Handler-setup).

# Description

The German department has a website students can use to practise translating
English words to German. It's flawed in a great number of ways, most notably
by using a static list of words to translate, which is repeated in the same
order on every run: run a chapter more than a few times and you end up simply
memorizing the order of the words, not learning them.

Vokab is an attempt to do better. When the program is launched, several words with
the highest scores are displayed in English, and the user must enter their
German translations. If the German is incorrect, the correct translation is
shown. The score is computed based on the Wilson score; the selection criteria
are described in detail in the internals docs: doc/word-selection.md

# Synopsis

vokab \[--help\] \[--verbose|quiet\] \[options\]

    Options:
      --help      print a brief help message and quit
      --man       print the full program description and quit
      --verbose   use verbose logging (give twice for more detail)
      --quiet     silence all log output
