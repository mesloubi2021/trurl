#!/usr/bin/env perl

use strict;
use warnings;
use 5.13.9; # minimum version for JSON::PP

# set STDOUT, STDIN & STDERR to use UTF-8
use open qw/:std :utf8/;

use Test::More;
use JSON::PP;
use Cwd qw(realpath);
use File::Basename qw(dirname);
use File::Spec::Functions qw(catfile curdir);
use IO::All; # libio-all-perl
use IPC::Run qw(start finish); # libipc-run-perl
#use Text::ParseWords qw(shellwords);

use version;

#use Data::Dumper;

if ($^O eq 'MSWin32') {
    #use Win32;
    #print Win32::GetACP();
    require Win32::Console;
    Win32::Console->import();
    # set cmd to use utf8 code page
    Win32::Console::OutputCP(65001);
    require Win32::ShellQuote;
    Win32::ShellQuote->import(qw(quote_literal));
} else {
    require String::ShellQuote;
    String::ShellQuote->import(qw(shell_quote));
}
sub shlex_join {
    return (($^O eq 'MSWin32')?join q{ }, map { quote_literal($_) } @_:shell_quote(@_));
}

use constant PROGNAME => 'trurl';
use constant TESTFILE => 'tests.json';

my $basedir = dirname(realpath($0));
my $curdir = curdir();
my $sep = catfile('', '');
my $basecmd = (join '', ($curdir, $sep, PROGNAME, (($^O eq 'MSWin32')?'.exe':'')));

my $h = start [$basecmd, '--version'], \undef, \my $out, \my $err;
finish $h;
chomp $out;
my ( $libcurl_runtime, $libcurl_buildtime ) = $out =~ / libcurl\/([\w\.\-]+) \[built\-with ([\w\.\-]+)\]$/;
#print "\$out=$out\n\$libcurl_runtime=$libcurl_runtime\n\$libcurl_buildtime=$libcurl_buildtime\n";
$libcurl_runtime = version->parse($libcurl_runtime);
$libcurl_buildtime = version->parse($libcurl_buildtime);

# read TESTFILE contents into $json variable
my $json < io catfile($basedir, TESTFILE);
my $tests = decode_json($json);
my $testcount = @{$tests};
plan tests => $testcount;

foreach my $test (@{$tests}) {
    my $arguments = $test->{input}->{arguments};
    my $expected = $test->{expected};
    my $expected_stdout = $expected->{stdout};
    # the hash mark in some tests appears to cause Test::More to escape the test name
    #my $test_name = (join '', ('./', PROGNAME, ' ', $cmdline));
    #printf "reftype:%s\n", ref($arguments);
    #@arguments = @arguments[0..$#arguments];
    my @cmdfull = @{ $arguments };
    unshift @cmdfull, $basecmd;
    #print "cmdfull: ";
    #print Dumper(\@cmdfull);
    my @cmdshort = @{ $arguments };
    unshift @cmdshort, './' . PROGNAME;
    #print "cmdshort: ";
    #print Dumper(\@cmdshort);
    my $test_name = shlex_join(@cmdshort);
    #print Dumper($test_name);
    #my @cmd = [ \@{$basecmd}, @arguments ];
    #print "cmd: ";
    #print Dumper(@cmd);
    SKIP: {
        if (exists $test->{minruntime}) {
            my $minruntime = version->parse($test->{minruntime});
            skip("libcurl run-time version is too low: $libcurl_runtime < $minruntime", 1)
                unless $libcurl_runtime >= $minruntime;
        }
        if (exists $test->{minbuildtime}) {
            my $minbuildtime = version->parse($test->{minbuildtime});
            skip("libcurl build-time version is too low: $libcurl_buildtime < $minbuildtime", 1)
                unless $libcurl_buildtime >= $minbuildtime;
        }
        my $h = start \@cmdfull, \undef, \my $out, \my $err;
        finish $h;
        if (ref($expected_stdout)) { # json test
            $out = decode_json($out);
        }
        #if (!ref($expected_stdout)) {
        #    chomp $out;
        #} else { # json test
        #    $out = decode_json($out);
        #}
        #if (length($err)) { # $err contains the output from stderr
        #    chomp $err;
        #}
        # build a hashtable containing $out, $returncode, and $err and compare to the expected values
        my %commandOutput = (
            "stdout" => $out,
            "returncode" => $h->full_result(0), # will be 7 for test 5
            "stderr" => $err
        );
        is_deeply(\%commandOutput, $expected, $test_name);
    }
}

done_testing();
