#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::Plugin::Session::Store::MongoDB' );
}

diag( "Testing Catalyst::Plugin::Session::Store::MongoDB $Catalyst::Plugin::Session::Store::MongoDB::VERSION, Perl $], $^X" );
