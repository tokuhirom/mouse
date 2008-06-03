#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 12;

do {
    package Class;
    use Mouse;

    has pawn => (
        is        => 'rw',
        predicate => 'has_pawn',
    );

    no Mouse;
};

my $meta = Class->meta;
isa_ok($meta, 'Mouse::Class');

is_deeply([$meta->superclasses], ['Mouse::Object'], "correctly inherting from Mouse::Object");

my $meta2 = Class->meta;
is($meta, $meta2, "same metaclass instance");

can_ok($meta, 'name', 'attributes', 'get_attribute_map');

my $attr = $meta->get_attribute('pawn');
isa_ok($attr, 'Mouse::Attribute');
is($attr->name, 'pawn', 'got the correct attribute');

my $map = $meta->get_attribute_map;
is_deeply($map, { pawn => $attr }, "attribute map");

eval "
    package Class;
    use Mouse;
    no Mouse;
";

my $meta3 = Class->meta;
is($meta, $meta3, "same metaclass instance, even if use Mouse is performed again");

is($meta->name, 'Class', "name for the metaclass");

do {
    package Child;
    use Mouse;
    extends 'Class';
};

my $child_meta = Child->meta;
isa_ok($child_meta, 'Mouse::Class');

isnt($meta, $child_meta, "different metaclass instances for the two classes");

is_deeply([$child_meta->superclasses], ['Class'], "correct superclasses");
