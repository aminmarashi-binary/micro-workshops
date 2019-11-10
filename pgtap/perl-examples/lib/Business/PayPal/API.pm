package Business::PayPal::API;

use strict;
use warnings;

sub new {
    my $class = shift;

    return bless {@_}, $class;
}

sub SendMoney {
    die "Not implemented!";
}

1;
