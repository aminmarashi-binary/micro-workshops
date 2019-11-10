use warnings;
use strict;

use Test::More;
use Payment;

subtest 'Can send a money to a user' => sub {
    my $payment_api = Payment->new(
        username => 'amin',
        password => 'SeCuRe321',
    );


    Payment::mock();

    my $result = $payment_api->send_money(
        email => 'amin@binary.com',
        amount => 20_000_000,
        currency => 'BTC',
    );

    my @args = Payment::unmock();

    is_deeply(\@args, ['amin@binary.com', 'BTC 20000000'], "SendMoney is called with correct arguments");
    ok($result->{success}, 'A success message is received');
};

done_testing();

1;
