#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;



# RT #37569

{
    package MyObject;
    use Mouse;

    package Foo;
    use Mouse;
    use Mouse::Util::TypeConstraints;

    subtype 'MyArrayRef'
       => as 'ArrayRef'
       => where { defined $_->[0] }
       => message { ref $_ ? "ref: ". ref $_ : 'scalar' }  # stringy
    ;

    subtype 'MyObjectType'
       => as 'Object'
       => where { $_->isa('MyObject') }
       => message {
          if ( $_->isa('SomeObject') ) {
            return 'More detailed error message';
          }
          elsif ( blessed $_ ) {
            return 'Well it is an object';
          }
          else {
            return 'Doh!';
          }
       }
    ;

    type 'NewType'
       => where { $_->isa('MyObject') }
       => message { blessed $_ ? 'blessed' : 'scalar' }
    ;

    has 'obj' => ( is => 'rw', isa => 'MyObjectType' );
    has 'ar'  => ( is => 'rw', isa => 'MyArrayRef' );
    has 'nt'  => ( is => 'rw', isa => 'NewType' );
}

my $foo = Foo->new;
my $obj = MyObject->new;

throws_ok {
    $foo->ar( [] );
}
qr/Attribute \(ar\) does not pass the type constraint because: ref: ARRAY/,
    '... got the right error message';

throws_ok {
    $foo->obj($foo);    # Doh!
}
qr/Attribute \(obj\) does not pass the type constraint because: Well it is an object/,
    '... got the right error message';

throws_ok {
    $foo->nt($foo);     # scalar
}
qr/Attribute \(nt\) does not pass the type constraint because: blessed/,
    '... got the right error message';

