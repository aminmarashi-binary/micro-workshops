use strict;
use warnings;
no indirect;

use Test::More::Async;
use Ryu::Async;
use IO::Async::Loop;
use Future::AsyncAwait;
use feature qw(state);
# use Log::Any::Adapter qw(Stdout), log_level => 'TRACE';
my $loop = IO::Async::Loop->new;

sub create_source {
    $loop->add(our $ryu = Ryu::Async->new) unless $ryu;

    return $ryu->source;
}

subtest 'A source is created then receives items' => async sub {
    my $source = create_source();

    # Emit the item in the next loop
    $loop->later(sub { $source->emit('item') });

    my $item;
    $source->each(sub {$item = shift});

    await $loop->delay_future(after => 0.1);

    is $item, 'item', 'The emitted item is received';
};

subtest 'A finished source does not receive any items' => async sub {
    my $source = create_source();

    $loop->later(sub { $source->emit('item') });

    my $item;
    $source->each(sub {$item = shift});

    $source->finish;

    await $loop->delay_future(after => 0.1);

    is $item, undef, 'nothing received';
};

subtest 'A cancelled source does not receive any items' => async sub {
    my $source = create_source();

    $loop->later(sub { $source->emit('item') });

    my $item;
    $source->each(sub {$item = shift});

    $source->cancel;

    await $loop->delay_future(after => 0.1);

    is $item, undef, 'nothing received';
};

subtest 'When parents are finished, children continue living' => async sub {
    my $parent = create_source();

    my $child = $parent->chained(label => 'child');

    $parent->finish;

    is $child->completed->state, 'pending', 'child is finished';
};

subtest 'A child which is bound to the parent output is finished when parent finishes' => async sub {
    my $parent = create_source();

    my $child = $parent->with_index;

    $parent->finish;

    is $child->completed->state, 'done', 'child is finished';
};

subtest 'A child which is bound to the parent output is cancelled when parent is cancelled' => async sub {
    my $parent = create_source();

    my $child = $parent->with_index;

    $parent->cancel;

    is $child->completed->state, 'cancelled', 'child is cancelled';
};

subtest 'When all children are finished the parent source is cancelled' => async sub {
    my $parent = create_source();

    my $child = $parent->chained(label => 'child');

    $child->finish;

    is $parent->completed->state, 'cancelled', 'parent is cancelled';
};

done_testing();
1;
