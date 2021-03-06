#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;



=pod

This test demonstrates the ability to extend
Mouse meta-level classes using Mouse itself.

=cut

{
    package My::Meta::Class;
    use Mouse;

    extends 'Mouse::Meta::Class';

    around 'create_anon_class' => sub {
        my $next = shift;
        my ($self, %options) = @_;
        $options{superclasses} = [ 'Mouse::Object' ]
            unless exists $options{superclasses};
        $next->($self, %options);
    };
}

my $anon = My::Meta::Class->create_anon_class();
isa_ok($anon, 'My::Meta::Class');
isa_ok($anon, 'Mouse::Meta::Class');
isa_ok($anon, 'Class::MOP::Class');

is_deeply(
    [ $anon->superclasses ],
    [ 'Mouse::Object' ],
    '... got the default superclasses');

{
    package My::Meta::Attribute::DefaultReadOnly;
    use Mouse;

    extends 'Mouse::Meta::Attribute';

    around 'new' => sub {
        my $next = shift;
        my ($self, $name, %options) = @_;
        $options{is} = 'ro'
            unless exists $options{is};
        $next->($self, $name, %options);
    };
}

{
    my $attr = My::Meta::Attribute::DefaultReadOnly->new('foo');
    isa_ok($attr, 'My::Meta::Attribute::DefaultReadOnly');
    isa_ok($attr, 'Mouse::Meta::Attribute');
    isa_ok($attr, 'Class::MOP::Attribute');

    ok($attr->has_reader, '... the attribute has a reader (as expected)');
    ok(!$attr->has_writer, '... the attribute does not have a writer (as expected)');
    ok(!$attr->has_accessor, '... the attribute does not have an accessor (as expected)');
}

{
    my $attr = My::Meta::Attribute::DefaultReadOnly->new('foo', (is => 'rw'));
    isa_ok($attr, 'My::Meta::Attribute::DefaultReadOnly');
    isa_ok($attr, 'Mouse::Meta::Attribute');
    isa_ok($attr, 'Class::MOP::Attribute');

    ok(!$attr->has_reader, '... the attribute does not have a reader (as expected)');
    ok(!$attr->has_writer, '... the attribute does not have a writer (as expected)');
    ok($attr->has_accessor, '... the attribute does have an accessor (as expected)');
}

