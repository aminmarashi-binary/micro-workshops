package Ryu::Source;

use strict;
use warnings;
no indirect;

# TODO: Add support for IO::Async::Notifier

# Just save all the args in $self
sub new {
    my ($class, %args) = @_;

    # Required to make the source finished (not covered in the first session)
    # defined $args{new_future} or die 'Please pass the new_future function';

    my $self = { callbacks => [], %args };
    return bless $self, $class;
}

# Create a new instance of source, mostly used internally
sub create_source {
    my ($self, %args) = @_;

    return __PACKAGE__->new(%args);
}

# Emit new items to the source
sub emit {
    my ($self, $item) = @_;

    $_->($item) for $self->{callbacks}->@*;
}

# Listen on items reaching the source
# ->each(sub {warn shift})
sub each {
    my ($self, $code) = @_;

    push $self->{callbacks}->@*, $code;

    return $self;
}

# Skip a few items from the source
sub skip {
    my ($self, $count) = @_;

    my $new_source = $self->create_source();

    $self->each(sub {
        my $item = shift;
        $new_source->emit($item) unless $count-- > 0;
    });

    return $new_source;
}

# Returns items and their index: [$item, $idx]
sub with_index {
    my ($self) = @_;

    my $new_source = $self->create_source();

    my $count = 0;
    $self->each(sub {
        my $item = shift;
        $new_source->emit([ $item, $count++ ]);
    });

    return $new_source;
}

# Similar to map function, changes a received item based on a coderef
sub map {
    my ($self, $code) = @_;

    my $new_source = $self->create_source();

    $self->each(sub {
        my $item = shift;
        $new_source->emit($code->($item));
    });

    return $new_source;
}

# Filter items based on a regex
sub filter {
    my ($self, $code) = @_;

    my $new_source = $self->create_source();

    $self->each(sub {
        my $item = shift;
        $new_source->emit($item) if $code->($item);
    });

    return $new_source;
}

# Return distinct values, duplicate values are dropped
sub distinct {
    my ($self, $code) = @_;

    my $new_source = $self->create_source();

    my %seen;
    $self->each(sub {
        my $item = shift;
        $new_source->emit($item) unless $seen{$item}++;
    });

    return $new_source;
}

#############################################################################
# Need `completed` implementation. Will talk about them in the next session #
#############################################################################

# Returns a future which is done when the source is completed
sub completed {
}

# Completes the source
sub finish {
}

# Take n items from the source
sub take {
}

# Take first item from the source
sub first {
}

# Count the numbers received
sub count {
}

# Return an accumulative result, similar to reduce in List::Util
sub reduce {
}

# Returns all items as an array ref
sub as_arrayref {
}

# Every good source should clean after itself
sub cleanup {
}

1;
