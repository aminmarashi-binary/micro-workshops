package Downloader;

use strict;
use warnings;
no indirect;

use parent qw(IO::Async::Notifier);

use mro;
use Ryu::Async;
use Net::Async::HTTP;
use URI;

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

    return $self->{src} = $self->file_stream($src) if -f $src;

    return $self->{src} = $self->http_stream($src) if URI->new($src)->scheme =~ /^https?$/;
}

sub http_stream {
    my ($self, $src) = @_;

    $self->loop->add(
        my $http = Net::Async::HTTP->new(),
    );

    my $source = $self->ryu->source;

    $http->do_request(
        uri => URI->new($src),
        on_header => sub {
            return sub {
                return $source->finish unless @_;

                $source->emit(shift);
            };
        },
    );

    return $source;
}

sub file_stream {
    my ($self, $src) = @_;

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

    return $source;
}

sub run {
    my ($self) = @_;

    $self->src->completed;
}

1;
