use strict;
use warnings;
no indirect;

use Test::More;
use Test::AsyncSubtest;

use Net::Async::BinaryWS;
use IO::Async::Loop;
use Future::AsyncAwait;

my $loop = IO::Async::Loop->new;
$loop->add(
    my $ws = Net::Async::BinaryWS->new(
        app_id => 3012,
        endpoint => 'ws.binaryws.com',
    )
);
my $api = $ws->api;

subtest 'ping' => async sub {
    await $ws->connected;

    my $msg = await $api->ping;

    is $msg->body, 'pong', 'pong is received';
};

subtest 'Subscribe to ticks and get three' => async sub {
    await $ws->connected;

    my @ticks = await (
        $api
        ->subscribe(ticks => 'R_100', subscribe => 1)
        ->take(3)
        ->as_list
    );

    is_deeply [map { $_->type } @ticks], [qw(tick tick tick)], 'The returned value is an array of ticks';
};

subtest 'Subscribe to ticks and get three' => async sub {
    await $ws->connected;

    my @price_list = await (
        $api
        ->subscribe(proposal => {
            subscribe => 1,
            amount => 10,
            currency => 'USD',
            basis => 'stake',
            contract_type => 'PUT',
            symbol => 'frxUSDJPY',
            duration => 5,
            duration_unit => 'm',
        })
        ->map(sub { shift->body->payout })
        ->take(2)
        ->as_list
    );

    is scalar @price_list, 2, 'We got two prices';
    for my $price (@price_list) {
        ok $price > 10, 'payout must be greater than stake';
    }
};

done_testing;
1;
