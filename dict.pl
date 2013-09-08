#!/usr/bin/perl

=pod

dict.pl

Author: Chen Gang
Blog: http://blog.yikuyiku.com
Corp: SINA
At 2013-08-13 Beijing

=cut


use strict;
use warnings;

open my $fh,"<",shift;
while(<$fh>)
{
	chomp;
	my ($e, $c) = split /\t/;
	$e =~ s/\'//g;
	$c =~ s/\'//g;
	next if $e =~ /\s/;
	next if $e =~ /\-/;
	next if $e =~ /\./;
	next unless $c;
	print "INSERT INTO dictData (English,Chinese) VALUES ('$e', '$c');";
	print "\n";
}

