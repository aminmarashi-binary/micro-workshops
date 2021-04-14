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

    # What do I get from ping?
    is $msg->body, '', 'ping was successful';
};

subtest 'Subscribe to ticks and get three' => async sub {
    await $ws->connected;

    my @ticks = await (
        $api
        ->subscribe(ticks => 'R_100', subscribe => 1)
        ->take(3)
        ->as_list
    );

    # What type of response I expect?
    is_deeply [map { $_->type } @ticks], [], 'Three ticks are received';
};

subtest 'Subscribe to ticks and get three' => async sub {
    await $ws->connected;

    my $two_prices = $api
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
        ->map(sub { shift->body->ask_price })
        ->take(2);

    my @price_list; # Get the price list
    # Get me my price list
    is scalar @price_list, 2, 'We got two prices';
    for my $price (@price_list) {
        is $price, 10, 'Price should be ask_price = 10';
    }
};

done_testing;
1;
