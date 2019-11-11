use strict;
use warnings;

use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

my $input = 'hello world!';

$loop->add(
    my $uploader = Uploader->new(
        chunks => sub {
            my ($idx, $chunk_size) = @_;
            substr $input, $idx, $chunk_size;
        },
        size => length $input,
        delay => 1,
    )
);

print $uploader->upload->get . "\n";

package Uploader;

use strict;
use warnings;
no indirect;

use parent qw(IO::Async::Notifier);

use mro;
use Future::AsyncAwait;

sub configure {
    my ($self, %args) = @_;
    for my $k (qw(size chunks delay)) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }
    $self->next::method(%args);
}

sub size { shift->{size} // 0 }
sub chunk_size { shift->{chunk_size} //= 4 }
sub idx { shift->{idx} // 0 }
sub delay { shift->{delay} //= 0.1 } # 100ms
sub chunks { shift->{chunks} //= sub {} }

async sub upload {
    my ($self) = @_;

    my $output;

    my $idx = 0;
    for(;;await $self->loop->delay_future(after => $self->delay)) {
        $output .= $self->chunks->($idx, $self->chunk_size);
        $idx += $self->chunk_size;
        last unless length $output < $self->size;
    }

    return $output;
}
