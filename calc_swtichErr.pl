#!/usr/bin/perl -w

die "Usage: perl $0 true.dateset.txt ALLHiC.hapVar.snps\n" if(!defined($ARGV[0]) and !defined($ARGV[1]));

open(IN, $ARGV[0]) or die"";
while(<IN>){
	chomp;
	my @data = split(/\s+/,$_);
	my $key = $data[0]."_".$data[1];
	my ($geno,$id) = (split/:/,$data[4])[0,5]; 
	if($geno eq "0|1"){
		$genoB = $data[2]."|".$data[3];
	}else{
		$genoB = $data[3]."|".$data[2];
	}
	$PBWHdb{$key} = $geno.":".$genoB.":".$id;
}
close IN;

my %block_dir = ();
open(IN, $ARGV[1]) or die"";
while(<IN>){
	chomp;
	my @data = split(/\s+/,$_);
	my $key  = $data[0]."_".$data[1];
	next if(!exists($PBWHdb{$key}));
	my $infor = $PBWHdb{$key};
	my @tmpdb = split(/:/,$infor);
	my $bid   = $data[0]."-".$tmpdb[2];
	$tmpdb[0]=~s/\|.*//;
	$block_dir{$bid}->{'Abase'} .= $tmpdb[0];
}
close IN;

my $sum_t = 0;
my $sum_e = 0;
open(OUT, "> switch_error.stat") or die"";
print OUT "BLOCK-ID	No_of_SNP	No_of_switchedSNP	Error_rate(%)\n";
foreach my $bid (sort keys %block_dir){
	my $seq = $block_dir{$bid}->{'Abase'};
	   $seq =~ s/\s+//g;
	my $Num_t = length $seq;
	my $Num_1 = ($seq=~tr/1/I/);
	my $Num_0 = ($seq=~tr/0/O/);
	my $Num_e = ($Num_1<$Num_0)?$Num_1:$Num_0;
	my $erate = sprintf("%.2f",$Num_e/$Num_t*100);
	$sum_t += $Num_t;
	$sum_e += $Num_e;
	print OUT "$bid	$Num_t	$Num_e	$erate\n";
	if($Num_1>$Num_0){
		$block_dir{$bid}->{'Direction'} = "-";
	}else{
		$block_dir{$bid}->{'Direction'} = "+";
	}
}
close OUT;

$erate_t = sprintf("%.2f",$sum_e/$sum_t*100);
print "Total Number of SNPs:	$sum_t\n";
print "Total Number of switched SNPs:	$sum_e\n";
print "Switch error:	$erate_t\n";

open(OUT, "> validate_phased.txt") or die"";
open(IN, $ARGV[1]) or die"";
while(<IN>){
	chomp;
	my @data = split(/\s+/,$_);
	my $key  = $data[0]."_".$data[1];
	next if(!exists($PBWHdb{$key}));
	my $infor = $PBWHdb{$key};
	my @tmpdb = split(/:/,$infor);
	my $bid   = $data[0]."-".$tmpdb[2];
	my $dir   = $block_dir{$bid}->{'Direction'};
	my $geno  = ($dir eq "+")?"0|1":"1|0";
	print OUT "$_	$PBWHdb{$key}	R\n" if($geno eq $tmpdb[0]);
	print OUT "$_	$PBWHdb{$key}	W\n" if($geno ne $tmpdb[0]);
}
close IN;
close OUT;



