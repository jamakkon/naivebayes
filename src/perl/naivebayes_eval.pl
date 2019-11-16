#!/usr/bin/perl

use strict;
use warnings;

binmode(STDIN, ":encoding(UTF-8)");
binmode(STDOUT, ":encoding(UTF-8)");
binmode(STDERR, ":encoding(UTF-8)");

my $modelfile = $ARGV[0];

my %P_CLASSES = ();
my %P_FEATURES = ();
my $P_FEATURES_IN_CLASS = {};
read_model($modelfile, \%P_CLASSES, \%P_FEATURES, \$P_FEATURES_IN_CLASS);

my @DECISIONS = ();
while (<STDIN>) {
    chomp();
    if (/^(\w+)\t(.*)$/) {
	my $class = $1;
	my @vector = split(/\W+/, lc($2));

	my ($judgment, $likelihood) = classify($class, \@vector, \%P_CLASSES, \%P_FEATURES, \$P_FEATURES_IN_CLASS);
	my $decision = {};
	$decision->{'target'} = $class;
	$decision->{'judgment'} = $judgment;
	$decision->{'likelihood'} = $likelihood;

	push(@DECISIONS, $decision);
    }
}

my $results = {};
foreach my $decision (@DECISIONS) {
    $results->{$decision->{'target'}}->{'targets'}++;
    if ($decision->{'target'} eq $decision->{'judgment'}) {
	$results->{$decision->{'target'}}->{'truepositive'}++;
    } else {
	$results->{$decision->{'target'}}->{'falsenegative'}++;
	$results->{$decision->{'judgment'}}->{'falsepositive'}++;
    }
}

print "RESULTS:\n";

foreach my $c (sort keys %{$results}) {

    my $p = $results->{$c}->{'truepositive'} / ($results->{$c}->{'truepositive'} + $results->{$c}->{'falsepositive'});
    my $r = $results->{$c}->{'truepositive'} / ($results->{$c}->{'targets'});
    my $f1 = 2.0 * $p * $r / ($p + $r);

    print "$c\t$results->{$c}->{'targets'}\t$p\t$r\t$f1\n";
}




sub classify {
    my ($target, 
	$ref_vector, 
	$ref_pclass,
	$ref_pfeature,
	$ref_pfgivenc) = @_;

    my $marginal_likelihood = 0.0;
    foreach my $c (keys %{$ref_pclass}) {	
	my $p_fgivenc = 1.0;
	foreach my $f (@{$ref_vector}) {
	    $p_fgivenc *= ${$ref_pfgivenc}->{$c}->{$f};
	}
	my $p_c = ${$ref_pclass}{$c};

	$marginal_likelihood += $p_c * $p_fgivenc;
    }


    my $best_class = undef;
    my $max_likelihood = -1.0;

    foreach my $c (keys %{$ref_pclass}) {	
	my $p_fgivenc = 1.0;
	foreach my $f (@{$ref_vector}) {
	    $p_fgivenc *= ${$ref_pfgivenc}->{$c}->{$f};
	}
	my $p_c = ${$ref_pclass}{$c};

	my $likelihood = $p_c * $p_fgivenc / $marginal_likelihood;
	if ($max_likelihood < $likelihood) {
	    $best_class = $c;
	    $max_likelihood = $likelihood;
	}
    }

    return ($best_class, $max_likelihood);
}



sub read_model {
    my ($filename,
	$ref_pclass,
	$ref_pfeature,
	$ref_pfgivenc) = @_;


    open(FILE, "<$filename") or die("Cannot open model file $filename");
    while (<FILE>) {
	chomp();

	if (/^p\_c\t(\w+)\t([0-9.]+)$/) {
	    ${$ref_pclass}{$1} = $2;
	} elsif (/^p\_f\t(\w+)\t([0-9.]+)$/) {
	    ${$ref_pfeature}{$1} = $2;
	} elsif (/^p\_f\_given\_c\t(\w+)\t(\w+)\t([0-9.]+)$/) {
	    ${$ref_pfgivenc}->{$1}->{$2} = $3;
	} else {
	    print STDERR "Cannot parse model line: $_\n";
	}
    }
    close(FILE);
    
}
