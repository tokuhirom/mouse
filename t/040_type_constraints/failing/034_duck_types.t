#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

{

    package Duck;
    use Mouse;

    sub quack { }

}

{

    package Swan;
    use Mouse;

    sub honk { }

}

{

    package RubberDuck;
    use Mouse;

    sub quack { }

}

{

    package DucktypeTest;
    use Mouse;
    use Mouse::Util::TypeConstraints;

    duck_type 'DuckType' => qw(quack);
    duck_type 'SwanType' => [qw(honk)];

    has duck => (
        isa        => 'DuckType',
        is => 'ro',
        lazy_build => 1,
    );

    sub _build_duck { Duck->new }

    has swan => (
        isa => duck_type( [qw(honk)] ),
        is => 'ro',
    );

    has other_swan => (
        isa => 'SwanType',
        is => 'ro',
    );

}

# try giving it a duck
lives_ok { DucktypeTest->new( duck => Duck->new ) } 'the Duck lives okay';

# try giving it a swan which is like a duck, but not close enough
throws_ok { DucktypeTest->new( duck => Swan->new ) }
qr/Swan is missing methods 'quack'/,
    "the Swan doesn't quack";

# try giving it a rubber RubberDuckey
lives_ok { DucktypeTest->new( swan => Swan->new ) } 'but a Swan can honk';

# try giving it a rubber RubberDuckey
lives_ok { DucktypeTest->new( duck => RubberDuck->new ) }
'the RubberDuck lives okay';

# try with the other constraint form
lives_ok { DucktypeTest->new( other_swan => Swan->new ) } 'but a Swan can honk';
