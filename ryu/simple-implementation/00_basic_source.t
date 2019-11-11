use strict;
use warnings;
no indirect;


use Test::More;
use Ryu::Session1;

subtest 'Initialize' => sub {
    my $source = Ryu::Source->new;

    isa_ok $source, 'Ryu::Source', 'Source is initialized correctly';
};

subtest 'Can emit and receive items' => sub {
    my $source = Ryu::Source->new;

    my $received;
    $source->each(sub {
        $received = shift;
    });

    $source->emit('item');

    is $received, 'item', 'Item is received';
};

subtest 'Items emitted are dropped if no one is listening' => sub {
    my $source = Ryu::Source->new;

    my $received;
    $source->emit('item');

    $source->each(sub {
        $received = shift;
    });

    is $received, undef, 'Item will be dropped';
};

subtest 'Items are skipped properly' => sub {
    my $source = Ryu::Source->new;

    my @items;
    $source->skip(2)->each(sub {push @items, shift});

    $source->emit($_) for 1..5;

    is_deeply \@items, [3, 4, 5], '1 and 2 are skipped';
};

subtest 'Items are returned with their indexes' => sub {
    my $source = Ryu::Source->new;

    my @items;
    $source->with_index->each(sub {push @items, shift});

    $source->emit($_) for 1..5;

    is_deeply \@items, [map [$_, $_ - 1], 1..5], 'Items match expectation';
};

subtest 'Mapped items are returned' => sub {
    my $source = Ryu::Source->new;

    my @items;
    $source->map(sub { "#" . shift })->each(sub {push @items, shift});

    $source->emit($_) for 1..5;

    my @expected = map "#" . $_, 1..5;

    is_deeply \@items, \@expected, 'Are items are now prefixed';
};

subtest 'Filter returns the filtered items' => sub {
    my $source = Ryu::Source->new;

    my @items;
    $source->filter(sub {$_[0] % 2})->each(sub {push @items, shift});

    $source->emit($_) for 1..5;

    is_deeply \@items, [1, 3, 5], 'Only odd numbers pass the filter';
};

subtest 'Distinct numbers are seen' => sub {
    my $source = Ryu::Source->new;

    my @items;
    $source->distinct->each(sub {push @items, shift});

    $source->emit($_) for 1, 2, 2, 3, 4, 2, 4, 5, 3;

    is_deeply \@items, [1..5], 'All the numbers from 1 to 5 are seen once';
};

subtest 'Combined sources work' => sub {
    my $source = Ryu::Source->new;

    my @items;
    $source
        ->filter(sub {$_[0] % 2})
        ->skip(1)
        ->distinct
        ->with_index
        ->each(sub {push @items, shift});

    $source->emit($_) for 1, 2, 2, 4, 2, 4, 5, 3;

    is_deeply \@items, [
        # Put the expected items here
        [5, 0],
        [3, 1],
    ], 'Make me pass';
};

subtest 'Combined sources work two each' => sub {
    my $source = Ryu::Source->new;

    my @items;
    $source
        ->filter(sub {$_[0] % 2})
        ->each(sub {push @items, shift})
        ->skip(1)
        ->distinct
        ->with_index
        ->each(sub { push @items, shift });

    my @expected = (1, 2, 2, 4, 2, 4, 5, 3);
    $source->emit($_) for @expected;

    # diag explain \@items;
    is_deeply \@items, [
        # Put the expected items here
        1, 5, [5, 0], 3, [3, 1]
    ], 'Make me pass';
};

done_testing();
1;
