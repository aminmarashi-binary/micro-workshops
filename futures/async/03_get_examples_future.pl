#!/usr/bin/perl -l

use strict;
use warnings;

=head1 Get example pages asynchronously (using Futures)

The L<Future> module provides various ways to get the result of and/or combine futures.

=cut

use IO::Async::Loop;
use Net::Async::HTTP;

my $loop = IO::Async::Loop->new;
my $http = Net::Async::HTTP->new;
$loop->add($http);

my @domains = qw(example.com example.org example.net);

my @futures = map { $http->do_request(uri => URI->new("http://$_")) } @domains;

print "This is after the non-blocking do_request";

=pod

Futures can be grouped together and be treated as a batch of requests. L<Future> provides
means various actions on a group of futures. For example C<needs_all> can be used to wait
until all the futures in a group are done and get all the results in an I<array>.

=cut

my @contents = map { $_->content } Future->needs_all(@futures)->get;

for my $content (@contents) {
    print 'Received: ' . length($content) . ' bytes';
}

1;
