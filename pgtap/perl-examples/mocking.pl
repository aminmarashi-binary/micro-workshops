use warnings;
use strict;

use Test::More;
use Math;
use AdvancedMath;

subtest 'Math module works properly' => sub {
    is(Math::add(1,3), 4, 'Add works fine');
    is(Math::divide(6,3), 2, 'Divide works fine');
};

subtest 'AdvancedMath works correctly' => sub {
    # Start mocking before calculating average
	Math::mock();	

    # average now works with our mocked math module
    AdvancedMath::average(1, 2);

    # unmock returns the args in order they were called
	my @args = Math::unmock();

    # Check if the arguments are passed to Math methods as we expect
    is_deeply(\@args, [1, 2, -1, 2], 'Mocked math module is called as expected to calculate average');
};

subtest 'AdvancedMath and Math work correctly together' => sub {
    is(AdvancedMath::average(1,3), 2, 'Average is calculated correctly');
};

done_testing();

1;
