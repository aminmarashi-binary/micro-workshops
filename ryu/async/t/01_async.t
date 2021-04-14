use strict;
use warnings;
no indirect;

use Test::More;
use Test::JsonWebSocket;

use Async::WebSocket;
use IO::Async::Loop;
use Future::AsyncAwait;
use Ryu::Source;

my $src;    # This is a source that we define per test
my $loop = IO::Async::Loop->new;
$loop->add(
    my $ws = Async::WebSocket->new(
        app_id   => 3012,
        host     => 'ws.binaryws.com',
        on_frame => sub {
            return unless defined $src;
            $src->emit(shift);
        },
    ));

subtest 'Ping the API' => sub {
    $src = Ryu::Source->new;
    $ws->connected->get;
    my $response = $loop->new_future;
    $src->each(
        sub {
            $response->done($_);
        });
    $ws->send({ping => 1})->get;
    my $msg = $response->get;
    is $msg->{ping}, 'pong', 'pong is received';
};

subtest 'Can take three ticks from the API' => sub {
    $src = Ryu::Source->new;
    $ws->send({ticks => 'R_100'})->get;
    my @ticks = $src->take(3)->as_list->get;
    is_deeply [map { $_->{msg_type} } @ticks], [qw(tick tick tick)], 'The returned value is an array of ticks';
};

done_testing;
1;
