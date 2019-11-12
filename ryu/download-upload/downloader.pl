use strict;
use warnings;

use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

my $output;
$loop->add(
    my $downloader = Downloader->new(
        chunks => sub {
            my ($chunk) = @_;

            $output .= $chunk if $chunk;
        },
        delay => 1,
    )
);

$downloader->download->get;
print $output . "\n";

package Downloader;

use strict;
use warnings;
no indirect;

use parent qw(IO::Async::Notifier);

use mro;
use Future::AsyncAwait;

sub configure {
    my ($self, %args) = @_;
    for my $k (qw(chunks delay)) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }
    $self->next::method(%args);
}

sub delay { shift->{delay} //= 0.1 } # 100ms
sub chunks { shift->{chunks} //= sub {} }
sub data { "hello world!!!" }

async sub download {
    my ($self) = @_;

    my $idx = 0;
    my $chunk_size = 4;
    for(;;await $self->loop->delay_future(after => $self->delay)) {
        $self->chunks->(substr $self->data, $idx, $chunk_size);
        $idx += $chunk_size;
        last if $idx + 1 > length $self->data;
    }

    $self->chunks->(); # end of file
}
