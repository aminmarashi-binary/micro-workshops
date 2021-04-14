use strict;
use warnings;
no indirect;

use Test::More;
use Test::AsyncSubtest;

use Net::Async::BinaryWS;
use IO::Async::Loop;
use Future::AsyncAwait;
use curry::weak;

my $loop = IO::Async::Loop->new;
$loop->add(
    my $ws = Net::Async::BinaryWS->new(
        app_id => 3012,
        endpoint => 'ws.binaryws.com',
    )
);
my $api = $ws->api;

sub merge_r_50_and_r_100 {
    my $src_r_50 = $api->subscribe(ticks => 'R_50');
    my $src_r_100 = $api->subscribe(ticks => 'R_100');

    # same as $combined = $src_r_100->merge($src_r_50);
    # but we can't use that in this example
    my $combined = $api->new_source;
    $src_r_100
    ->each($combined->curry::weak::emit);
    $src_r_50
    ->each($combined->curry::weak::emit);

    $combined
    ->each(sub {
        diag $_->body->ask
    })
    # What's the $combined source state now?
}

subtest 'A source finishes as soon as it is not needed' => async sub {
    await $ws->connected;

    # What will this print?
    merge_r_50_and_r_100();

    await $loop->delay_future(after => 6);

    pass '5 seconds passed';
};

done_testing;
1;
