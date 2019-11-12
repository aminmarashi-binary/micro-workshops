use strict;
use warnings;

use IO::Async::Loop;
use Net::Async::BinaryWS;
use Uploader;

my $loop = IO::Async::Loop->new;

$loop->add(
    my $binary_ws = Net::Async::BinaryWS->new(
        endpoint => 'wss://frontend.binaryws.com',
        app_id   => 1,
    ),
);

$binary_ws->connected->get;

my $api = $binary_ws->api;

my $source = $api->subscribe(ticks => 'R_100');

my $tick_stream = $source
->map(sub {
    my $envelope = shift;

    my $tick = $envelope->body;

    $tick->epoch . ',' . $tick->quote . ',' . $tick->ask . ',' . $tick->bid;
});

$loop->add(
    my $uploader = Uploader->new(
        src => $tick_stream,
        dst => './target_file',
    )
);

$uploader->run->get;

