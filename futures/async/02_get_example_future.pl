#!/usr/bin/perl -l

use strict;
use warnings;

=head1 Get an example page asynchronously (using Futures)

In this example we will get the example pages asynchronously using L<Future>. Futures are
essentially like callbacks. The difference being, the callee returns them to the caller
to tell the caller about the destiny of its request.

In this example we will make use of L<Net::Async::HTTP> which uses L<Future> to resolve
http requests.

=cut

use IO::Async::Loop;
use Net::Async::HTTP;

my $loop = IO::Async::Loop->new;
my $http = Net::Async::HTTP->new;
$loop->add($http);


my $future = $http->do_request(uri => URI->new("http://example.com"));

print "This is after the non-blocking do_request";

=pod

C<Future> is in fact a medium for the future response we expect from the http.
We need to wait until the future is ready before reading its content.

=cut

print "At this point the future is " . $future->state;

=head1 Get example pages asynchronously (using Futures)

The L<Future> module provides various ways to get the result of ready futures.
One simple way to do it is to use C<get> which blocks your code until the future is ready.
It then returns the result of the future.
General advice is only to call C<get> in the toplevel "main.pl"-style level of your code; or otherwise in places where you do want it to block.

=cut

# Wait to get the response
my $content = $future->get->content;

print 'Received: ' . length($content) . ' bytes';

print "At this point the future is " . $future->state;

1;
