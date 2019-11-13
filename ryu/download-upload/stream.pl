use strict;
use warnings;

use IO::Async::Loop;
use Uploader;
use Downloader;
use Getopt::Long;
use Pod::Usage;

=head1 NAME

streamer

=head1 SYNOPSIS

    perl streamer --from file:test --to s3://something

=head1 DESCRIPTION

Stream data from a source to a destination
the source and destination format is file:/path/to/file or http://uri.com

=cut

GetOptions(
    'from=s' => \my $from,
    'to=s'   => \(my $to = './target_file'),
) or pod2usage(2);

pod2usage(2) unless $from;

my $loop = IO::Async::Loop->new;

$loop->add(
    my $downloader = Downloader->new(
        src => $from,
    ),
);

$loop->add(
    my $uploader = Uploader->new(
        src => $downloader->src,
        dst => $to,
    )
);

$uploader->run->get;

