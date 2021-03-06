#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    eval "use IO::String; use IO::File;";
    plan skip_all => "IO::String and IO::File are required for this test" if $@;
    plan tests => 28;
}



{
    package Email::Mouse;
    use Mouse;
    use Mouse::Util::TypeConstraints;

    use IO::String;

    our $VERSION = '0.01';

    # create subtype for IO::String

    subtype 'IO::String'
        => as 'Object'
        => where { $_->isa('IO::String') };

    coerce 'IO::String'
        => from 'Str'
            => via { IO::String->new($_) },
        => from 'ScalarRef',
            => via { IO::String->new($_) };

    # create subtype for IO::File

    subtype 'IO::File'
        => as 'Object'
        => where { $_->isa('IO::File') };

    coerce 'IO::File'
        => from 'FileHandle'
            => via { bless $_, 'IO::File' };

    # create the alias

    my $st = subtype 'IO::StringOrFile' => as 'IO::String | IO::File';
    #::diag $st->dump;

    # attributes

    has 'raw_body' => (
        is      => 'rw',
        isa     => 'IO::StringOrFile',
        coerce  => 1,
        default => sub { IO::String->new() },
    );

    sub as_string {
        my ($self) = @_;
        my $fh = $self->raw_body();

        return do { local $/; <$fh> };
    }
}

{
    my $email = Email::Mouse->new;
    isa_ok($email, 'Email::Mouse');

    isa_ok($email->raw_body, 'IO::String');

    is($email->as_string, undef, '... got correct empty string');
}

{
    my $email = Email::Mouse->new(raw_body => '... this is my body ...');
    isa_ok($email, 'Email::Mouse');

    isa_ok($email->raw_body, 'IO::String');

    is($email->as_string, '... this is my body ...', '... got correct string');

    lives_ok {
        $email->raw_body('... this is the next body ...');
    } '... this will coerce correctly';

    isa_ok($email->raw_body, 'IO::String');

    is($email->as_string, '... this is the next body ...', '... got correct string');
}

{
    my $str = '... this is my body (ref) ...';

    my $email = Email::Mouse->new(raw_body => \$str);
    isa_ok($email, 'Email::Mouse');

    isa_ok($email->raw_body, 'IO::String');

    is($email->as_string, $str, '... got correct string');

    my $str2 = '... this is the next body (ref) ...';

    lives_ok {
        $email->raw_body(\$str2);
    } '... this will coerce correctly';

    isa_ok($email->raw_body, 'IO::String');

    is($email->as_string, $str2, '... got correct string');
}

{
    my $io_str = IO::String->new('... this is my body (IO::String) ...');

    my $email = Email::Mouse->new(raw_body => $io_str);
    isa_ok($email, 'Email::Mouse');

    isa_ok($email->raw_body, 'IO::String');
    is($email->raw_body, $io_str, '... and it is the one we expected');

    is($email->as_string, '... this is my body (IO::String) ...', '... got correct string');

    my $io_str2 = IO::String->new('... this is the next body (IO::String) ...');

    lives_ok {
        $email->raw_body($io_str2);
    } '... this will coerce correctly';

    isa_ok($email->raw_body, 'IO::String');
    is($email->raw_body, $io_str2, '... and it is the one we expected');

    is($email->as_string, '... this is the next body (IO::String) ...', '... got correct string');
}

{
    my $fh;

    open($fh, '<', $0) || die "Could not open $0";

    my $email = Email::Mouse->new(raw_body => $fh);
    isa_ok($email, 'Email::Mouse');

    isa_ok($email->raw_body, 'IO::File');

    close($fh);
}

{
    my $fh = IO::File->new($0);

    my $email = Email::Mouse->new(raw_body => $fh);
    isa_ok($email, 'Email::Mouse');

    isa_ok($email->raw_body, 'IO::File');
    is($email->raw_body, $fh, '... and it is the one we expected');
}



