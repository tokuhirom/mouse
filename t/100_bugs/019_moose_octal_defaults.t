#!/usr/bin/env perl
use Test::More tests => 10;

{
    my $package = qq{
package Test::Mouse::Go::Boom;
use Mouse;
use lib qw(lib);

has id => (
    isa     => 'Str',
    is      => 'ro',
    default => '019600', # this caused the original failure
);

no Mouse;

__PACKAGE__->meta->make_immutable;
};

    eval $package;
    $@ ? ::fail($@) : ::pass('quoted 019600 default works');
    my $obj = Test::Mouse::Go::Boom->new;
    ::is( $obj->id, '019600', 'value is still the same' );
}

{
    my $package = qq{
package Test::Mouse::Go::Boom2;
use Mouse;
use lib qw(lib);

has id => (
    isa     => 'Str',
    is      => 'ro',
    default => 017600,
);

no Mouse;

__PACKAGE__->meta->make_immutable;
};

    eval $package;
    $@ ? ::fail($@) : ::pass('017600 octal default works');
    my $obj = Test::Mouse::Go::Boom2->new;
    ::is( $obj->id, 8064, 'value is still the same' );
}

{
    my $package = qq{
package Test::Mouse::Go::Boom3;
use Mouse;
use lib qw(lib);

has id => (
    isa     => 'Str',
    is      => 'ro',
    default => 0xFF,
);

no Mouse;

__PACKAGE__->meta->make_immutable;
};

    eval $package;
    $@ ? ::fail($@) : ::pass('017600 octal default works');
    my $obj = Test::Mouse::Go::Boom3->new;
    ::is( $obj->id, 255, 'value is still the same' );
}

{
    my $package = qq{
package Test::Mouse::Go::Boom4;
use Mouse;
use lib qw(lib);

has id => (
    isa     => 'Str',
    is      => 'ro',
    default => '0xFF',
);

no Mouse;

__PACKAGE__->meta->make_immutable;
};

    eval $package;
    $@ ? ::fail($@) : ::pass('017600 octal default works');
    my $obj = Test::Mouse::Go::Boom4->new;
    ::is( $obj->id, '0xFF', 'value is still the same' );
}

{
    my $package = qq{
package Test::Mouse::Go::Boom5;
use Mouse;
use lib qw(lib);

has id => (
    isa     => 'Str',
    is      => 'ro',
    default => '0 but true',
);

no Mouse;

__PACKAGE__->meta->make_immutable;
};

    eval $package;
    $@ ? ::fail($@) : ::pass('017600 octal default works');
    my $obj = Test::Mouse::Go::Boom5->new;
    ::is( $obj->id, '0 but true', 'value is still the same' );
}
