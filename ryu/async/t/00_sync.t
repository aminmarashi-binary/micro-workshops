use strict;
use warnings;
no indirect;

use Test::More;
use Test::AsyncSubtest;
use Test::JsonWebSocket;

# This is not aware of IO::Async::Loop and therefore is not async
use Ryu::Source;
my $src = Ryu::Source->new;
sub on_frame {
    $src->emit(shift);
}

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

subtest 'Create a stream of ticks from the API' => async sub {
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
    plan skip_all => 'Not implemented';
    await $ws->send({ticks => 'R_100'});
    my @ticks = await $src->take(3)->as_list;
    is_deeply [map { $_->{msg_type} } @ticks], [qw(tick tick tick)], 'The returned value is an array of ticks';
};

done_testing;
1;
