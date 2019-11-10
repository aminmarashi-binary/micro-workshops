#!/usr/bin/perl -l

use strict;
use warnings;

=head1 Get an example page

In this example we get the I<example.com> page and print the size of it
using L<Mojo::UserAgent>.

=cut

use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;

my $result = $ua->get('http://example.com')->result;
my $content = $result->body;

print 'Received: ' . length($content) . ' bytes';

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

1;
