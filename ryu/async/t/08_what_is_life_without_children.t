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

subtest 'Keep living if children die' => async sub {
    await $ws->connected;

    my $ticks = $api
    ->subscribe(ticks => "R_100")
    ->map(sub { $_->body->ask });

    my @ticks = await $ticks->take(2)->as_list;

    is scalar @ticks, 2, 'two items received';

    @ticks = await $ticks->take(2)->as_list;

    is scalar @ticks, 2, 'two more items received';
};

done_testing;
1;
