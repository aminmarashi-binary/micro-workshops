package Ryu::Source;

use strict;
use warnings;
no indirect;

use Future;
use Syntax::Keyword::Try;
use Scalar::Util;

sub new { my $class = shift; bless { @_ }, $class }

sub filter {
    my ($self, $code) = @_;
 
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source(sub {
        $src->emit($_) if $code->($_);
    }, $src);
}

sub map {
    my ($self, $code) = @_;
 
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source(sub {
        $src->emit($code->($_));
    }, $src);
}

sub skip {
    my ($self, $count) = @_;
    $count //= 0;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source(sub {
        $src->emit($_) unless $count-- > 0;
    }, $src);
}

sub min {
    my ($self, $count) = @_;

    ## Can't use each_while_source here!
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my $min;
    $self->each(sub {
        return if defined $min and $min < $_;
        $min = $_;
    });
    $self->completed->on_done(sub { $src->emit($min) })
        ->on_ready($src->completed);
    $src
}

sub each_while_source {
    my ($self, $code, $src, %args) = @_;
    $self->each($code);
    $self->completed->on_ready(sub {
        my ($f) = @_;
        $f->on_ready($src->completed) unless $src->is_ready;
    });
    $src
}

sub chained {
    my ($self) = shift;
    my $src = __PACKAGE__->new(
        parent     => $self,
        @_
    );
    Scalar::Util::weaken($src->{parent});
    push @{$self->{children}}, $src;
    return $src;
}

sub each : method {
    my ($self, $code, %args) = @_;
    push @{$self->{on_item}}, $code;
    $self;
}

sub emit {
    my $self = shift;
    my $i = 1;
    my $completion = $self->completed;
    my @handlers = @{$self->{on_item} || []} or return $self;
    for (@_) {
        die 'already completed' if $completion->is_ready;
        for my $code (@handlers) {
            try {
                $code->($_);
            } catch {
                my $ex = $@;
                $completion->fail($ex, source => 'exception in on_item callback');
                die $ex;
            }
        }
    }
    $self
}


sub completed {
    my ($self) = @_;
    $self->{completed} //= do {
        my $f = $self->new_future(
            'completion'
        )->on_ready(sub {
            ## Cleanup
        });
        $f
    }
}

## Override with IO::Async::Loop->new_future to get Ryu::Async
sub new_future {
    my $self = shift;
    Future->new->set_label(@_);
}

for my $k (qw(then cancel fail on_ready on_done transform is_ready is_done is_failed failure is_cancelled else)) {
    do { no strict 'refs'; *$k = $_ } for sub { shift->completed->$k(@_) }
}

sub finish {
    $_[0]->completed->done unless $_[0]->is_ready
}

1;
