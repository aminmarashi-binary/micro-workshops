use strict;
use warnings;
no indirect;

use Test::More;
use Test::AsyncSubtest;
use Test::Exception;

use Net::Async::BinaryWS;
use IO::Async::Loop;
use Future::AsyncAwait;
use Syntax::Keyword::Try;

my $loop = IO::Async::Loop->new;
$loop->add(
    my $ws = Net::Async::BinaryWS->new(
        app_id => 3012,
        endpoint => 'ws.binaryws.com',
    )
);
my $api = $ws->api;

subtest 'What error? I do not know what you are talking about' => async sub {
    await $ws->connected;

    # Make me die if you can!
    throws_ok {
        $api
        ->subscribe(ticks => "R_200")
        ->each(sub {
            die 'source, die!';
        })
    } qr/die/, 'error should be caught';
};

done_testing;
1;
