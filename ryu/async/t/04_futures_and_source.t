use strict;
use warnings;
no indirect;

use Test::More;
use Test::AsyncSubtest;

use IO::Async::Loop;
use Future::AsyncAwait;

my $loop = IO::Async::Loop->new;
use Ryu::Async;
$loop->add(
    my $ryu = Ryu::Async->new
);

my $src = $ryu->source(label => 'counter');
(async sub {
    for my $count (0..1000) {
        await ($loop->delay_future(after => 1));
        $src->emit($count);
    }
})
->()
->on_ready($src->completed)
->retain;


subtest 'An interval source, emits a count every second' => async sub {
    my @items = await (
        $src
        ->each(sub {
            diag $_;
        })
        ->take(5)
        ->as_list
    );

    # Give me what I want, with the format I expect
    is_deeply \@items, [map { "item: $_" } 0..4], '5 items are received'; 
};

done_testing;
1;
