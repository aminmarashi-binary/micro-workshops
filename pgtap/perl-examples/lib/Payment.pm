package Payment;

use strict;
use warnings;
no warnings qw/redefine/;

use Business::PayPal::API;

sub new {
    my ($class, %credentials) = @_;

    return bless {
        api => new Business::PayPal::API (
                %credentials,
                PKCS12File     => '/path/to/cert.pkcs12',
                PKCS12Password => 'VerySecurePassword!',
                sandbox        => 1,
                )
    }, $class;
}

sub send_money {
    my ($self, %transaction) = @_;

    my ($email, $amount, $currency) = @{transaction}{qw/email amount currency/};

    return $self->{api}->SendMoney($email, "$currency $amount");
}

my @args;
my $orig;

sub mock {
    $orig = Business::PayPal::API->can('SendMoney');

    *Business::PayPal::API::SendMoney = sub {
        my $self = shift;
        push @args, @_; 
        return {
            success => 1,
        }
    };
}

sub unmock {
    *Business::PayPal::API::SendMoney = $orig;
    return @args;
}

1;
