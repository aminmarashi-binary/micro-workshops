use strict;
use warnings;
no indirect;

use Test::More;
use Test::AsyncSubtest;
use Test::JsonWebSocket;

# WS is async
use Async::WebSocket;
use IO::Async::Loop;
use Future::AsyncAwait;
my $loop = IO::Async::Loop->new;
$loop->add(
    my $ws = Async::WebSocket->new(
        app_id => 3012,
        host => 'ws.binaryws.com',
        on_frame => \&on_frame,
    )
);
# Now let's get Ryu::Async working
use Ryu::Async;
$loop->add(
    my $ryu = Ryu::Async->new
);
# This is a source that we define per test
my $src;
sub on_frame {
    return unless defined $src;
    $src->emit(shift);
}

subtest 'Subscribe to proposals' => async sub {
    $src = $ryu->source(label => 'proposal'); # a new source per test is always a good idea
    await $ws->connected;
    await $ws->send({
        proposal => 1,
        subscribe => 1,
        amount => 10,
        currency => 'USD',
        basis => 'stake',
        contract_type => 'PUT',
        symbol => 'frxUSDJPY',
        duration => 5,
        duration_unit => 'm',
    });
    my @price_list = await (
        $src
        ->each(sub {
            diag explain shift;
        })
        ->take(2)
        ->map(sub {
            shift->{proposal}{payout}
        })
        ->as_list
    );
    is scalar @price_list, 2, 'We got two prices';
    for my $price (@price_list) {
        ok $price > 10, 'payout must be greater than stake';
    }
};

done_testing;
1;
