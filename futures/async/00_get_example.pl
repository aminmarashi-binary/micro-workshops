#!/usr/bin/perl -l

use strict;
use warnings;

=head1 Get an example page asynchronously

In this example we will get one page I<asynchronously>, which means
we will use I<non-blocking> C<get> to fetch the example page, i.e. we don't
have to I<wait> until the requested page is ready to execute the next line of
code.

=cut

use Mojo::UserAgent;

my $ua  = Mojo::UserAgent->new;


=head2 The callback

L<Mojo::UserAgent> Provides I<callbacks> for fetching pages asynchronously.
Callbacks are functions that are called when the result of the http request
is ready. L<Mojo::UserAgent> then calls the callbacks with the http response.

=cut

$ua->get("http://example.com", sub { # The callback
    my ($ua, $tx) = @_;
    my $content = $tx->result->body;

    print 'Received: ' . length($content) . ' bytes';
});

print "This is after the non-blocking get";

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

1;
