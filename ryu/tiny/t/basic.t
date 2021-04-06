use strict;
use warnings;
no indirect;

use Test::More;
use Test::Exception;
use Ryu::Source;

my $ryu;

subtest 'Initialize Ryu::Source' => sub {
    ok $ryu = Ryu::Source->new, 'instantiated correctly';
    isa_ok $ryu, 'Ryu::Source';
};

subtest 'Emitted items are received in each' => sub {
    my @items = (1, 2, 3, 'a', 'b', 'c');

    my @received;
    $ryu
    ->each(sub {
        push @received, shift;
    });

    $ryu->emit(@items);

    is_deeply \@received, \@items, 'All items are received';
};

subtest 'Ryu::Source->filter' => sub {
    my @items = (2, 30, 22, 5, 60, 1);

    my @received;
    $ryu
    ->filter(sub {
        shift > 10
    })
    ->each(sub {
        push @received, shift;
    });

    $ryu->emit(@items);

    is_deeply \@received, [30, 22, 60], 'Only 3 are received';
};

subtest 'Ryu::Source->map' => sub {
    my @items = (1, 2, 3);

    my @received;
    $ryu
    ->map(sub {
        10 * shift
    })
    ->each(sub {
        push @received, shift;
    });

    $ryu->emit(@items);

    is_deeply \@received, [10, 20, 30], 'items are 10x';
};

subtest 'Ryu::Source->skip' => sub {
    my @items = (1, 2, 3, 4);

    my @received;
    $ryu
    ->skip(2)
    ->each(sub {
        push @received, shift;
    });

    $ryu->emit(@items);

    is_deeply \@received, [3, 4], '2 items are skipped';
};

subtest 'Ryu::Source->min' => sub {
    my @items = (2, 30, 22, 5, 60, 1);

    my @received;
    $ryu
    ->min
    ->each(sub {
        push @received, shift;
    });

    $ryu->emit(@items);
    $ryu->finish;

    is_deeply \@received, [1], 'Only 1 is received';
};

subtest 'Ryu::Source->emit after src is done' => sub {
    ok $ryu->is_ready, 'Source is already completed';
    throws_ok { $ryu->emit('item') } qr/already completed/, 'Cannot emit after completion';
};

done_testing;
1;
