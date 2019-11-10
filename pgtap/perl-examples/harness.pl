use warnings;
use strict;

use Date::Utility;
use Test::More;
use License;

ok (1, 'It is OK') or diag("Logic does not work on this planet");

note "Show me!";
# print "Why not show me?";

SKIP: {
    skip "It is weekend", 1 if Date::Utility->new("2018-06-17")->day_of_week % 6 == 0;
    ok(0, "I shall fail");
}

TODO: {
    my ($car, $license) = (undef, License->new(expiry => time + 9999));
    local $TODO="I don't have a car yet!" unless $car;
    ok($license->is_valid, "I can drive") or diag("I can't drive with my license: ", explain($license));
}

# BAIL_OUT("Don't want more tests");
# ok(0, "Why this happened? I'm outa here!");

done_testing();

1;
