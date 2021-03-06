#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;
use Test::Exception;

BEGIN {
    use_ok('Mouse::Util::TypeConstraints');
}

{
    package Gorch;
    use Mouse;

    package Bar;
    use Mouse;

    package Foo;
    use Mouse;

    extends qw(Bar Gorch);

}

lives_ok { class_type 'Beep' } 'class_type keywork works';
lives_ok { class_type('Boop', message { "${_} is not a Boop" }) }
  'class_type keywork works with message';

my $type = find_type_constraint("Foo");

is( $type->class, "Foo", "class attribute" );

ok( $type->is_subtype_of("Gorch"), "subtype of gorch" );

ok( $type->is_subtype_of("Bar"), "subtype of bar" );

ok( $type->is_subtype_of("Object"), "subtype of Object" );

ok( !$type->is_subtype_of("ThisTypeDoesNotExist"), "not subtype of undefined type" );
ok( !$type->is_a_type_of("ThisTypeDoesNotExist"), "not type of undefined type" );

ok( find_type_constraint("Bar")->check(Foo->new), "Foo passes Bar" );
ok( find_type_constraint("Bar")->check(Bar->new), "Bar passes Bar" );
ok( !find_type_constraint("Gorch")->check(Bar->new), "but Bar doesn't pass Gorch");

ok( find_type_constraint("Beep")->check( bless {} => 'Beep' ), "Beep passes Beep" );
my $boop = find_type_constraint("Boop");
ok( $boop->has_message, 'Boop has a message');
my $error = $boop->get_message(Foo->new);
like( $error, qr/is not a Boop/,  'boop gives correct error message');


ok( $type->equals($type), "equals self" );
ok( $type->equals(Mouse::Meta::TypeConstraint::Class->new( name => "__ANON__", class => "Foo" )), "equals anon constraint of same value" );
ok( $type->equals(Mouse::Meta::TypeConstraint::Class->new( name => "Oink", class => "Foo" )), "equals differently named constraint of same value" );
ok( !$type->equals(Mouse::Meta::TypeConstraint::Class->new( name => "__ANON__", class => "Bar" )), "doesn't equal other anon constraint" );
ok( $type->is_subtype_of(Mouse::Meta::TypeConstraint::Class->new( name => "__ANON__", class => "Bar" )), "subtype of other anon constraint" );

