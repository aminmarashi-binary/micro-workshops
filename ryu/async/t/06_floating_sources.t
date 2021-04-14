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
    my $merged_ticks = shift;
    my $src_r_50 = $api->subscribe(ticks => 'R_50');
    my $src_r_100 = $api->subscribe(ticks => 'R_100');

    ## same as $combined = $src_r_100->merge($src_r_50);
    ## but we can't use that in this example
    my $combined = $api->new_source;
    $src_r_100
    ->each($combined->curry::weak::emit);
    $src_r_50
    ->each($combined->curry::weak::emit);

    $combined
    ->each(sub {
        push @$merged_ticks, $_->body->ask;
    })
}

subtest 'A source finishes as soon as it is not needed' => async sub {
    await $ws->connected;

    my $merged_ticks = [];
    merge_r_50_and_r_100($merged_ticks);

    # Count to 5
    for my $count (1..5) {
        diag $count;
        await $loop->delay_future(after => 1);
    }

    # Give me some ticks, I have nothing!
    ok scalar @$merged_ticks > 0, 'One or more ticks are received';
};

done_testing;
1;
