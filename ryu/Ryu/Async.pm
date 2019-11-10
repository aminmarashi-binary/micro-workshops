package Ryu::Async;

use strict;
use warnings;
no indirect;

use parent 'IO::Async::Notifier';

use Ryu::Source;

sub source {
    my ($self) = @_;

    Ryu::Source->new(
        new_future => sub { $self->loop->new_future(@_) }
    );
}

1;
