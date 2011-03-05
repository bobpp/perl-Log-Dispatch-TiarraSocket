#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Log::Dispatch::TiarraSocket' ) || print "Bail out!
";
}

diag( "Testing Log::Dispatch::TiarraSocket $Log::Dispatch::TiarraSocket::VERSION, Perl $], $^X" );
