package Downloader;

use strict;
use warnings;
no indirect;

use parent qw(IO::Async::Notifier);

use mro;
use Ryu::Async;

sub configure {
    my ($self, %args) = @_;
    for my $k (qw(src)) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }
    $self->next::method(%args);
}

sub ryu {
    my ($self) = @_;

    return $self->{ryu} if $self->{ryu};

    $self->loop->add(
        my $ryu = Ryu::Async->new
    );

    return $ryu;
}

sub src {
    my ($self) = @_;

    my $src = $self->{src};

    return $src if ref($src) and $src->isa('Ryu::Source');

    my $source = $self->ryu->source;

    open(my $fh, '<', $src) or die "Cannot open file $src for read $!";

    $source->{on_get} = sub {
        $self->loop->later(sub {
            while(read $fh, my $buf, 4096) {
                $source->emit($buf);
            }
            $source->finish;
        });
    };

    return $self->{src} = $source;
}

sub run {
    my ($self) = @_;

    $self->src->completed;
}

1;
