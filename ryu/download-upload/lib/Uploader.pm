package Uploader;

use strict;
use warnings;
no indirect;

use parent qw(IO::Async::Notifier);

use mro;
use Ryu::Async;

sub configure {
    my ($self, %args) = @_;
    for my $k (qw(src dst)) {
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

sub dst {
    my ($self) = @_;

    my $dst = $self->{dst};

    return $dst if ref($dst) and $dst->isa('Ryu::Source');

    my $source = $self->ryu->source;

    return $self->{dst} = $source
    ->each(sub {
        my $line = shift;

        open(my $fh, '>>', $dst) or die "Cannot open file $dst for write: $!";
        print $fh $line;
        close $fh;
    });
}

sub src {
    my ($self) = @_;

    my $src = $self->{src};

    return $src if ref($src) and $src->isa('Ryu::Source');

    return $self->{src} = Ryu->from($src);
}

sub run {
    my ($self) = @_;

    $self
    ->src
    ->each(sub {
        $self->dst->emit(shift);
    })
    ->completed
    ->on_ready($self->dst->completed);
}

1;
