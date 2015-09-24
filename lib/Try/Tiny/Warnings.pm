package Try::Tiny::Warnings;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: extension to Try::Tiny to also catch warnings
$Try::Tiny::Warnings::VERSION = '0.0.1';

use strict;
use warnings;

use Exporter;
use Try::Tiny;

use parent 'Exporter';

our @EXPORT = qw/ try_warnings try_fatal_warnings catch_warnings /;

sub try_fatal_warnings(&;@) { 
    my($sub,@rest) = @_;
    local $SIG{__WARN__} = \&CORE::die;
    try { $sub->() } @rest;
};

sub try_warnings(&;@) {  
    my($sub,@rest) = @_;

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    @rest = map {
        my $x = $_;
        ref $_ eq 'Try::Tiny::Warnings::Catch' 
            ? finally { $x->(@warnings) }
            : $_
    } @rest;

    try { $sub->() } @rest;
};

sub catch_warnings(&;@) {  
    my( $sub, @rest ) = @_;
    $sub = bless $sub, 'Try::Tiny::Warnings::Catch';
    return( $sub, @rest );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Try::Tiny::Warnings - extension to Try::Tiny to also catch warnings

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    use Try::Tiny;
    use Try::Tiny::Warnings;

    {
        package Foo;

        use warnings;

        sub bar { 1 + shift }
    }

    Foo::bar();  # warn

    # makes 'warn' behave like 'die'
    try_fatal_warnings {
        Foo::bar();
    }
    catch {
        print "tsk, got $_";
    };

    # warnings are captured and passed
    # to 'catch_warnings'
    try_warnings {
        Foo::bar();
        warn "some more";
    }
    catch {
        print "won't be printed\n";
    }
    catch_warnings {
        print "we warned with: $_" for @_;
    };

=head1 DESCRIPTION

C<Try::Tiny::Warnings> adds a few keywords to L<Try::Tiny> 
to deal with warnings.

The first keyword, C<try_fatal_warnings>, behaves like
C<try>, excepts that it also makes any C<warn()> within its block
behave like C<die()>. If the block dies because of such a fatalized 
warn, it'll be C<catch>ed in the usual way.

    try_fatal_warnings {
        warn "uh oh";
    }
    catch {
        print $_; # prints 'uh oh'
    };

The two other keywords are meant to be used together.
C<try_warnings> also behaves like C<try>, but also capture
all warnings issued within the block. The captured
warnings will be passed to C<catch_warnings>, which is a 
specialized C<finally> block. Just like regular C<finally> blocks, 
many C<catch_warnings> 
blocks can be used if you so desire.

    try_warnings {
        warn "oops!";
        $x = 4;
    }
    finally {
        $y = $x + 3;
    }
    catch_warnings {
            # percolate up non-silly warnings
        warn for grep { !/oops/ } @_;    
    };

Note that using C<catch_warnings> with C<try_fatal_warnings> is pointless.

Also, because C<catch_warnings> is a C<finally> in disguise, it has to come after
the regular C<catch> clause.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
