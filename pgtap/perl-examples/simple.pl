use strict;
use warnings;

use Test::Simple tests => 7;

ok(1, "1 is true");
ok(1 == 1, "equal works");
ok(0 != 1, "not equal works");

ok(1 + 1 == 2, "Add works");
ok(1 - 1 == 0, "Subtract works");
ok(4 / 2 == 2, "Divide works");
ok(2 * 2 == 4, "multiply works");
# Not very helpful description:
# ok(1 + 1 == 2, "1 + 1 = 2");
# It's not immediately obvious what expected to work when it fails

1;
