#!/usr/bin/env perl

use strict;
use warnings;
use 5.13.9; # minimum version for JSON::PP

use Test::More;
use JSON::PP;
use Cwd qw(realpath);
use File::Basename qw(dirname);
use File::Spec::Functions qw(catfile curdir);
use IO::All; # may need libio-all-perl
use IPC::Run qw(start finish);
use Text::ParseWords qw(shellwords);

use constant PROGNAME => 'trurl';
use constant TESTFILE => 'tests.json';

my $basedir = dirname(realpath($0));
my $curdir = curdir();
my $sep = catfile('', '');
my $basecmd = (join '', ($curdir, $sep, PROGNAME, (($^O eq 'MSWin32')?'.exe':'')));
# read TESTFILE contents into $json variable
my $json < io catfile($basedir, TESTFILE);
my $tests = decode_json($json);
my $testcount = @{$tests};
plan tests => $testcount;

foreach my $test (@{$tests}) {
    my $cmdline = $test->{cmdline};
    my $expected = $test->{expected};
    my $expected_stdout = $expected->{stdout};
    # the hash mark in some tests appears to cause Test::More to escape the test name
    my $test_name = (join '', ('./', PROGNAME, ' ', $cmdline));
    my $h = start [ $basecmd, shellwords($cmdline) ], \undef, \my $out, \my $err;
    finish $h;
    if (!ref($expected_stdout)) {
        chomp $out;
    } else { # json test
        $out = decode_json($out);
    }
    if (length($err)) { # $err contains the output from stderr
        chomp $err;
    }
    # build a hashtable containing $out, $returncode, and $err and compare to the expected values
    my %commandOutput = (
        "stdout" => $out,
        "returncode" => $h->full_result(0), # will be 7 for test 5
        "stderr" => $err
    );
    is_deeply(\%commandOutput, $expected, $test_name);
}

done_testing();
