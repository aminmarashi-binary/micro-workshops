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
        app_id   => 3012,
        host     => 'ws.binaryws.com',
        on_frame => \&on_frame,
    ));
# Now let's get Ryu::Async working
use Ryu::Async;
$loop->add(my $ryu = Ryu::Async->new);
# This is a source that we define per test
my $src;

sub on_frame {
    return unless defined $src;
    $src->emit(shift);
}

subtest 'Subscribe to proposals' => async sub {
    $src = $ryu->source(label => 'proposal');    # a new source per test is always a good idea
    await $ws->connected;
    await $ws->send({
        proposal      => 1,
        subscribe     => 1,
        amount        => 10,
        currency      => 'USD',
        basis         => 'stake',
        contract_type => 'PUT',
        symbol        => 'frxUSDJPY',
        duration      => 5,
        duration_unit => 'm',
    });
    $loop->delay_future(after => 5)->then(sub { $src->finish })->retain;
    my @price_list = await(
        $src->each(sub { diag $_->{msg_type} })
            # ->each(sub { diag explain $_->{proposal} })
            # Put something here
            ->as_list
    );
    # Get me ask_price of the proposals
    for my $price (@price_list) {
        is $price, 10, 'Price should be ask_price = 10';
    }
};

done_testing;
1;
