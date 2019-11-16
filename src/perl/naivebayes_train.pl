#!/usr/bin/perl

use strict;
use warnings;

binmode(STDIN, ":encoding(UTF-8)");
binmode(STDOUT, ":encoding(UTF-8)");
binmode(STDERR, ":encoding(UTF-8)");

# Read the training data.
#
my @DATA = ();
while (<STDIN>) {
    chomp();
    if (/^(\w+)\t(.*)$/) {
	my $sample = {};
	$sample->{'class'} = $1;
	push(@{$sample->{'features'}}, split(/\W+/, lc($2)));

	push(@DATA, $sample);
    }
}

# Build frequency maps.
#
my $total_samples = 0;
my %F_CLASSES = ();
my %F_FEATURES = ();
my $F_FEATURES_IN_CLASS = {};
foreach my $sample (@DATA) {
    $total_samples++;
    $F_CLASSES{$sample->{'class'}}++;

    foreach my $feature (@{$sample->{'features'}}) {
	$F_FEATURES{$feature}++;
	$F_FEATURES_IN_CLASS->{$sample->{'class'}}->{$feature}++;
    }
}

# Compute the probabilities.
#
my %P_CLASSES = ();
foreach my $c (keys %F_CLASSES) {
    # P(C) = #c / N 
    $P_CLASSES{$c} = 1.0 * $F_CLASSES{$c} / $total_samples;
}

my %P_FEATURES = ();
foreach my $f (keys %F_FEATURES) {
    # P(F) = #f / N
    $P_FEATURES{$f} = 1.0 * $F_FEATURES{$f} / $total_samples;
}

my $P_FEATURES_IN_CLASS = {};
foreach my $f (keys %F_FEATURES) {
    
    foreach my $c (keys %F_CLASSES) {
	if (defined($F_FEATURES_IN_CLASS->{$c}) && defined($F_FEATURES_IN_CLASS->{$c}->{$f})) {
	    $P_FEATURES_IN_CLASS->{$c}->{$f} = 1.0 * $F_FEATURES_IN_CLASS->{$c}->{$f} / $F_CLASSES{$c};
	} else {
	    $P_FEATURES_IN_CLASS->{$c}->{$f} = 0.0
	}
    }
}

# Write out the model.
#
foreach my $c (keys %P_CLASSES) {
    print "p_c\t$c\t$P_CLASSES{$c}\n";
}

foreach my $f (keys %P_FEATURES) {
    print "p_f\t$f\t$P_FEATURES{$f}\n";
}

foreach my $c (keys %{$P_FEATURES_IN_CLASS}) {
    foreach my $f (keys %{$P_FEATURES_IN_CLASS->{$c}}) {
	print "p_f_given_c\t$c\t$f\t$P_FEATURES_IN_CLASS->{$c}->{$f}\n";
    }
}
