package Math;

use strict;
use warnings;
no warnings qw/redefine/;

sub add { $_[0] + $_[1] }

sub divide { $_[0] / $_[1] }

my $orig;
my @args;

sub mock {
    $orig = { map { $_ => Math->can($_) } qw/divide add/ };

    # Mock divide and add to keep the arguments and return values
    *Math::add = sub { push @args, @_; return -1; };
    *Math::divide = sub { push @args, @_ };
}

sub unmock {
    # Restore the mocked methods for the next test
    no strict 'refs';
    *{"Math::$_"} = $orig->{$_} for qw/divide add/;

    return @args;
}

1;
