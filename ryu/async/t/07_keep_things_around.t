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
        app_id   => 3012,
        endpoint => 'ws.binaryws.com',
    ));
my $api = $ws->api;

subtest 'Keep the ticks around after 4 seconds' => async sub {
    await $ws->connected;

    my $take_two_s = $api->subscribe(ticks => "R_100")->map(sub { $_->body->ask })->take(2);

    # Count to 4
    for my $count (1 .. 4) {
        diag $count;
        await $loop->delay_future(after => 1);
    }
    $take_two_s->finish;

    my @ticks = await $take_two_s->as_list;
    # diag explain \@ticks;

    # Help me receive ticks
    ok scalar @ticks > 1, 'More than one tick is received';
};

done_testing;
1;
