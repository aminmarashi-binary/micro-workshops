package Test::JsonWebSocket;

use strict;
use warnings;
no indirect;

use Async::WebSocket;
use JSON::MaybeXS qw(encode_json decode_json);

{
    no warnings 'redefine';
    my $original_send = \&Async::WebSocket::send;
    *Async::WebSocket::send = sub {
        my $msg = pop;
        $original_send->(@_, ref($msg) ? encode_json($msg) : $msg);
    };
    my $original_on_frame = \&Async::WebSocket::on_frame;
    *Async::WebSocket::on_frame = sub {
        my $bytes = pop;
        $original_on_frame->(@_, decode_json($bytes));
    };
}

1;
