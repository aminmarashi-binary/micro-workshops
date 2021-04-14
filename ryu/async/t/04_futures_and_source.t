use strict;
use warnings;
no indirect;

use Test::More;
use Test::AsyncSubtest;

use IO::Async::Loop;
use Future::AsyncAwait;

my $loop = IO::Async::Loop->new;
use Ryu::Async;
$loop->add(my $ryu = Ryu::Async->new);

# Create a source using future
my $src = $ryu->source(label => 'counter');
(
    async sub {
        for my $count (1 .. 1000) {
            await($loop->delay_future(after => 1));
            $src->emit($count);
        }
    })->()->on_ready($src->completed)->retain;

subtest 'An interval source, emits a count every second' => async sub {
    my @items = await(
        $src->each(
            sub {
                diag $_;
            }
        # Create a future from a source
        )->take(3)->as_list
    );

    # Give me what I want, with the format I expect
    is_deeply \@items, [map { "item: $_" } 1 .. 3], 'All items are received';
};

subtest 'Return futures from a source' => async sub {
    my $src = $ryu->source(label => 'concurrent futures');

    my $items_f = $src
    ->concurrent
    ->take(5)
    ->as_list;

    # Emit delayed futures with random delays
    for my $idx (0..4) {
        my $random = int(3 * rand) + 1;
        $src->emit(
            $loop->delay_future(after => $random)
            ->transform(done => sub { +{ idx => $idx, after => $random } })
        );
    }

    my @items = await $items_f;
    # diag explain \@items;
    is_deeply [map { $_->{idx} } @items], [0..4], 'Items arrive in order';
};

done_testing;
1;
