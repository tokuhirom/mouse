package Foo;
use Mouse;

## Problem:
## lazy_build sets required => 1
## required does not permit setting to undef

## Possible solutions:
#### remove required => 1
#### check the attr to see if it accepts Undef (Maybe[], | Undef)
#### or, make required accept undef and use a predicate test


has 'foo' => ( isa => 'Int | Undef', is => 'rw', coerce => 1, lazy_build => 1 );
has 'bar' => ( isa => 'Int | Undef', is => 'rw', coerce => 1 );

sub _build_foo { undef }

package main;
use Test::More tests => 4;

ok ( !defined(Foo->new->bar), 'NonLazyBuild: Undef default' );
ok ( !defined(Foo->new->bar(undef)), 'NonLazyBuild: Undef explicit' );

ok ( !defined(Foo->new->foo), 'LazyBuild: Undef default/lazy_build' );

## This test fails at the time of creation.
ok ( !defined(Foo->new->foo(undef)), 'LazyBuild: Undef explicit' );


1;
