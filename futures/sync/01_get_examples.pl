#!/usr/bin/perl -l

use strict;
use warnings;

=head1 Get example pages

In this example we request the I<example.com>, I<example.org> and I<example.net> pages.

=cut

use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;

my @domains = qw(example.com example.org example.net);

my %sizes;
for my $domain (@domains) {
    my $result = $ua->get("http://$domain")->result;
    my $content = $result->body;

    $sizes{$domain} = length($content);
}

for my $domain (keys %sizes) {
    print 'Received: ' . $sizes{$domain} . ' bytes from ' . $domain;
}

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

1;
