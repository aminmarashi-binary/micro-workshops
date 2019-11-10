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

subtest 'Initialize' => sub {
    my $source = create_source();

    isa_ok $source, 'Ryu::Source', 'Source is initialized correctly';
};

subtest 'Items emitted are dropped if no one is listening' => async sub {
    my $source = create_source();

    $loop->later(sub { $source->finish });

    is $source->completed->state, 'pending', 'Source has not completed yet';

    await $loop->delay_future(after => 0.001);

    is $source->completed->state, 'done', 'Source has completed';
};

subtest 'Items emitted are dropped if no one is listening' => async sub {
    my $source = create_source();

    $source->emit('item');

    my $result_f = $source->first->as_list;

    await $loop->delay_future(after => 0.1);

    is $result_f->state, 'pending', 'Nothing will be received';
};

subtest 'Can emit and receive items' => async sub {
    my $source = create_source();

    $loop->later(sub { $source->emit('item') });

    my ($received) = await $source->first->as_list;

    is $received, 'item', 'Item is received';
};

subtest 'Items are skipped properly' => async sub {
    my $source = create_source();

    $loop->later(sub { $source->emit($_) for 1..5; $source->finish });

    my @items = await $source->skip(2)->as_list;

    is_deeply \@items, [3, 4, 5], '1 and 2 are skipped';
};

subtest 'Items are returned with their indexes' => async sub {
    my $source = create_source();

    $loop->later(sub { $source->emit($_) for 1..5; $source->finish });

    my @items = await $source->with_index->as_list;

    is_deeply \@items, [map [$_, $_ - 1], 1..5], 'Items match expectation';
};

subtest 'Mapped items are returned' => async sub {
    my $source = create_source();

    $loop->later(sub { $source->emit($_) for 1..5; $source->finish });

    my @items = await $source->map(sub { "#" . shift })->as_list;

    my @expected = map "#" . $_, 1..5;

    is_deeply \@items, \@expected, 'Are items are now prefixed';
};

subtest 'Filter returns the filtered items' => async sub {
    my $source = create_source();

    $loop->later(sub { $source->emit($_) for 1..5; $source->finish });

    my @items = await $source->filter(sub {$_[0] % 2})->as_list;

    my @expected = map "#" . $_, 1..5;

    is_deeply \@items, [1, 3, 5], 'Only odd numbers pass the filter';
};

subtest 'Distinct numbers are seen' => async sub {
    my $source = create_source();

    $loop->later(sub { $source->emit($_) for 1, 2, 2, 3, 4, 2, 4, 5, 3; $source->finish });

    my @items = await $source->distinct->as_list;

    is_deeply \@items, [1..5], 'All the numbers from 1 to 5 are seen once';
};
 
subtest 'Combined sources work' => async sub {
    my $source = create_source();

    $loop->later(sub { $source->emit($_) for 1, 2, 2, 4, 2, 4, 5, 3; $source->finish });

    my @items = await $source->distinct
        ->filter(sub {$_[0] % 2})
        ->skip(1)
        ->distinct
        ->with_index
        ->as_list;

    is_deeply \@items, [
        # Put the expected items here
        [5, 0],
        [3, 1],
    ], 'Make me pass';
};

subtest 'Combined sources work two each' => async sub {
    my $source = create_source();

    $loop->later(sub { $source->emit($_) for 1, 2, 2, 4, 2, 4, 5, 3; $source->finish });

    my @items;
    await $source->distinct
        ->filter(sub {$_[0] % 2})
        ->each(sub {push @items, shift})
        ->skip(1)
        ->distinct
        ->with_index
        ->each(sub { push @items, shift })
        ->as_list;


    # diag explain \@items;
    is_deeply \@items, [
        # Put the expected items here
        1, 5, [5, 0], 3, [3, 1]
    ], 'Make me pass';
};

###################
# Some more tests #
###################

subtest 'We can take some items from the source' => async sub {
    my $source = create_source();

    $loop->later(sub { $source->emit($_) for 1..5 });

    my @items = await $source->take(2)->as_list;

    is_deeply \@items, [1, 2], '1 and 2 are received';
};

subtest 'Count the items received' => async sub {
    my $source = create_source();

    $loop->later(sub { $source->emit($_) for 1..5 });

    my ($count) = await $source->take(3)->count->as_list;

    is $count, 3, 'Count matches the item taken from the source';
};

subtest 'Count the items received' => async sub {
    my $source = create_source();

    $loop->later(sub { $source->emit($_) for 1..5 });

    my ($count) = await $source->take(3)->count->as_list;

    is $count, 3, 'Count matches the item taken from the source';
};


done_testing();
1;
