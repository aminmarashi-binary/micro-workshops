package License;

use strict;
use warnings;

sub new {
    my $class = shift;
    return bless {@_}, $class;
}

sub is_valid {
    my $self = shift;

    return $self->{expiry} > time;
}

1;
