use strict;
use warnings;

use IO::Async::Loop;
use Uploader;
use Downloader;

my $loop = IO::Async::Loop->new;

$loop->add(
    my $downloader = Downloader->new(
        src => './source_file',
    ),
);

$loop->add(
    my $uploader = Uploader->new(
        src => $downloader->src,
        dst => './target_file',
    )
);

$uploader->run->get;

