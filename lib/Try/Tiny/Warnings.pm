package Try::Tiny::Warnings;

use strict;
use warnings;

use Exporter;
use Try::Tiny;

use parent 'Exporter';

our @EXPORT = qw/ try_warnings try_fatal_warnings catch_warnings /;

sub try_fatal_warnings(&;@) { 
    my($sub,@rest) = @_;
    local $SIG{__WARN__} = \&CORE::die; #sub { die @_ };
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



