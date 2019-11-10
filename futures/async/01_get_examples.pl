#!/usr/bin/perl -l

use strict;
use warnings;

=head1 Get example pages asynchronously

In this example we request the I<example.com>, I<example.org> and I<example.net> pages.

=cut

use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;

my @domains = qw(example.com example.org example.net);

my %sizes;
for my $domain (@domains) {
    $ua->get("http://$domain", sub { # The callback
        my ($ua, $tx) = @_;
        my $content = $tx->result->body;

        $sizes{$domain} = length($content);

        Mojo::IOLoop->stop if keys %sizes == 3; # This will let the results be printed
    });
}

# %sizes here does not contain what we want yet, we need to wait for the callbacks
# to stop the L<Mojo::IOLoop> and then we will have the %sizes.
print "This is after the non-blocking get";

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

for my $domain (keys %sizes) {
    print 'Received: ' . $sizes{$domain} . ' bytes from ' . $domain;
}

1;
