package Test::AsyncSubtest;
use strict;
use warnings;
no indirect;

use Test::More;
our @ISA = qw(Exporter);
our @EXPORT = qw(
  subtest
);

no warnings 'redefine';
sub subtest {
    my ($description, $code) = @_;
    my $r;
    Test::More::subtest($description, sub {
        $r = $code->();
        $r->get if $r->isa('Future');
    });
}

1;
