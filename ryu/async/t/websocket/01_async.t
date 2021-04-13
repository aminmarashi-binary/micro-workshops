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

subtest 'Ping the API' => async sub {
    $src = $ryu->source(label => 'ping'); # a new source per test is always a good idea
    my $response = $loop->new_future;
    $src->each(sub {
        $response->done(shift);
    });
    await $ws->connected;
    await $ws->send({ping => 1});
    my $msg = await $response;
    is $msg->{ping}, 'pong', 'pong is received';
};

subtest 'Can take three ticks from the API' => async sub {
    $src = $ryu->source(label => 'ticks'); # a new source per test is always a good idea
    await $ws->send({ticks => 'R_100'});
    my @ticks = await $src->take(3)->as_list;
    is_deeply [map { $_->{msg_type} } @ticks], [qw(tick tick tick)], 'The returned value is an array of ticks';
};

done_testing;
1;
