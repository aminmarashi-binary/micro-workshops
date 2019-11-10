package Test::More::Async;

use strict;
use warnings;
no indirect;

use Test::More ();
use Test2::API qw(context_do);
use Future::Utils qw(try_repeat);

require Exporter;
our @ISA = qw(Exporter);

our @tests;
our $current_subtest;
our $timeout = 5;

our @EXPORT = qw(ok use_ok require_ok
    is isnt like unlike is_deeply
    cmp_ok
    skip todo todo_skip
    pass fail
    eq_array eq_hash eq_set
    $TODO
    plan
    done_testing
    can_ok isa_ok new_ok
    diag note explain
    subtest
    BAIL_OUT
);

sub subtest {
    my ($description, $code) = @_;

    push @tests, [$description, $code];
};

sub done_testing {
    (try_repeat {
        my ($description, $code) = shift->@*;

        our $current_subtest = Subtest->new;

        my $result = $code->();

        if (ref($result) and $result->isa('Future')) {
            return Future->wait_any(
                $result->on_ready(sub { run_test($description) }),
                (!$result->is_ready ? $result->loop->delay_future(after => $timeout)
                ->on_done(sub {
                    Test::More::fail("`$description` did not finish within $timeout seconds");
                    $result->cancel;
                }) : Future->done),
            );
        } else {
            return Future->done(run_test($description));
        }
    } foreach => \@tests)->get;

    Test::More::done_testing();
}

sub run_test {
    my $description = shift;

    Test::More::subtest $description => sub {
        context_do {
            for my $check ($current_subtest->{calls}->@*) {
                my ($method, @args) = $check->@*;
                {
                    no strict 'refs';
                    "Test::More::$method"->(@args);
                }
            }
        }
    };
}

sub AUTOLOAD {
    my (@args) = @_;

    my ($method) = our $AUTOLOAD =~ /^.*::(.+)$/;

    $current_subtest->add_check($method, @args);
}

package Subtest;

sub new {bless {@_[1..$#_]}, $_[0]}

sub add_check {
    my ($self, $method, @args) = @_;

    push $self->{calls}->@*, [$method, @args];
}

1;
