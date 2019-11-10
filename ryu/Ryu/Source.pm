package Ryu::Source;

use strict;
use warnings;
no indirect;

use Scalar::Util;
use curry::weak;

# TODO: Add support for IO::Async::Notifier

# Just save all the args in $self
sub new {
    my ($class, %args) = @_;

    # Required to make the source finished (not covered in the first session)
    die 'Please pass the new_future function' unless defined $args{new_future};

    my $self = { callbacks => [], children => [], %args };
    return bless $self, $class;
}

# Create a new instance of source, mostly used internally
sub chained {
    my ($self, %args) = @_;

    my $new_source = __PACKAGE__->new(
        new_future => $self->{new_future},
        parent     => $self,
        %args,
    );

    Scalar::Util::weaken($new_source->{parent});

    Scalar::Util::weaken(my $weak_ref = $new_source);

    return $weak_ref;
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

sub each_while_source {
    my ($self, $code, $new_source, %options) = @_;

    $self->each($code);

    my $new_source_completed = $new_source->completed;
    $self->completed->on_ready($self->$curry::weak(sub {
        my ($self, $completed) = @_;
        $options{cleanup}->() if exists $options{cleanup};
        $completed->on_ready($new_source_completed);
        remove_from_array($self->{callbacks}, $code);
    }));

    return $new_source;
}

# Skip a few items from the source
sub skip {
    my ($self, $count) = @_;

    my $new_source = $self->chained;

    $self->each_while_source(sub {
        my $item = shift;
        $new_source->emit($item) unless $count-- > 0;
    }, $new_source);

    return $new_source;
}

# Returns items and their index: [$item, $idx]
sub with_index {
    my ($self) = @_;

    my $new_source = $self->chained;

    my $count = 0;
    $self->each_while_source(sub {
        my $item = shift;
        $new_source->emit([ $item, $count++ ]);
    }, $new_source);

    return $new_source;
}

# Similar to map function, changes a received item based on a coderef
sub map {
    my ($self, $code) = @_;

    my $new_source = $self->chained;

    $self->each_while_source(sub {
        my $item = shift;
        $new_source->emit($code->($item));
    }, $new_source);

    return $new_source;
}

# Filter items based on a regex
sub filter {
    my ($self, $code) = @_;

    my $new_source = $self->chained;

    $self->each_while_source(sub {
        my $item = shift;
        $new_source->emit($item) if $code->($item);
    }, $new_source);

    return $new_source;
}

# Return distinct values, duplicate values are dropped
sub distinct {
    my ($self, $code) = @_;

    my $new_source = $self->chained();

    my %seen;
    $self->each_while_source(sub {
        my $item = shift;
        $new_source->emit($item) unless $seen{$item}++;
    }, $new_source);

    return $new_source;
}

#############################################################################
# Need `completed` implementation. Will talk about them in the next session #
#############################################################################

# Returns a future which is done when the source is completed
sub completed {
    my $self = shift;

    $self->{completed} //= $self->{new_future}->()
    ->on_ready($self->$curry::weak(sub {
        shift->cleanup;
    }));

    return $self->{completed};
}

# Clean things up after finish
sub cleanup {
    my $self = shift;

    $self->{parent}->remove_child($self) if exists $self->{parent};

    $self->{callbacks} = [];
}

sub remove_child {
    my ($self, $child) = @_;

    remove_from_array($self->{children}, $child);

    $self->cancel unless $self->{children}->@*;
}

# Completes the source
sub finish {
    my $self = shift;

    $self->completed->done unless $self->completed->is_ready;
}

# Completes the source
sub cancel {
    shift->completed->cancel;
}

# Take first item from the source
sub first {
    my ($self, $code) = @_;

    my $new_source = $self->chained();

    $self->each_while_source(sub {
        $new_source->emit(shift);
        $new_source->finish;
    }, $new_source);

    return $new_source;
}

# Returns all items as a list
sub as_list {
    my ($self, $code) = @_;

    my $new_source = $self->chained();

    my @items;
    $self->each_while_source(sub {
        push @items, shift;
    }, $new_source);

    return $self->completed->transform(done => sub { @items });
}

# Take n items from the source
sub take {
    my ($self, $count) = @_;

    my $new_source = $self->chained();

    my @items;
    $self->each_while_source(sub {
        $new_source->emit(shift);
        return if --$count > 0;
        $new_source->finish;
    }, $new_source);

    return $new_source;
}

# Count the numbers received
sub count {
    my $self = shift;

    my $new_source = $self->chained();

    my $count;
    $self->each_while_source(sub {
        ++$count;
    }, $new_source, cleanup => sub {
        $new_source->emit($count);
    });

    return $new_source;
}

# nevermind this, we will use it later (instead of extract_by)
sub remove_from_array {
    my ($array, $item) = @_;

    if (ref($array) eq 'ARRAY' and $array->@*) {
        for my $i (0..$array->$#*) {
            if ($array->[$i] == $item) {
                return splice $array->@*, $i, 1;
            }
        }
    }

    return undef;
}

1;
