package Downloader;

use strict;
use warnings;
no indirect;

use parent qw(IO::Async::Notifier);

use mro;
use Ryu::Async;
use Net::Async::HTTP;
use Net::Async::BinaryWS;
use Future::AsyncAwait;
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

    my $uri = URI->new($src);

    die 'Unknown uri scheme: ' . $src unless $uri->scheme;

    return $self->{src} = $self->http_stream($uri) if $uri->scheme =~ /^https?$/;

    return $self->file_stream($uri->file) if $uri->scheme eq 'file';

    return $self->ticks_stream($uri->path) if $uri->scheme eq 'ticks';

    die 'Unknown file location: ' . $src;
}

sub ticks_stream {
    my ($self, $symbol) = @_;

    $self->loop->add(
        my $binary_ws = Net::Async::BinaryWS->new(
            endpoint => 'wss://frontend.binaryws.com',
            app_id   => 1,
        ),
    );

    my $new_source = $self->ryu->source; # not Ryu::Source->new has no new_future

    $binary_ws
    ->connected
    ->on_done(sub {
        my $api = $binary_ws->api;

        my $source = $api->subscribe(ticks => $symbol);

        $source
        ->each(sub {
            my $envelope = shift;

            my $tick = $envelope->body;

            $new_source->emit(
                $tick->epoch . ',' . $tick->quote . ',' . $tick->ask . ',' . $tick->bid
            );
        });
    })
    ->retain;

    return $new_source;
}

sub http_stream {
    my ($self, $uri) = @_;

    $self->loop->add(
        my $http = Net::Async::HTTP->new(),
    );

    my $source = $self->ryu->source;

    $http->do_request(
        uri => $uri,
        on_header => sub {
            my ($header) = @_;
            return sub {
                # do sth if $header->code eq 200
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
