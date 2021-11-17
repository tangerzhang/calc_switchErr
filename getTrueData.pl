#!/usr/bin/perl -w

die "Usage: perl $0 PB.WH.phase.txt 10x.WH.phase.txt\n" if(!defined($ARGV[0]) or !defined($ARGV[1]));

open(OUT, "> tmp.hapVarPB.txt") or die"";
open(IN, $ARGV[0]) or die"";
while(<IN>){
	chomp;
	my @data = split(/\s+/,$_);
	my $geno = (split/:/,$data[4])[0];
	if($geno eq "0|1"){
		$ha = $data[2]; $hb = $data[3];
	}elsif($geno eq "1|0"){
		$ha = $data[3]; $hb = $data[2];
	}
	print OUT "$data[0]	$data[1]	$ha	.	.	$hb\n";
}
close IN;
close OUT;

my %PBWHdb;
open(IN, $ARGV[1]) or die"";
while(<IN>){
	chomp;
	my @data = split(/\s+/,$_);
	my $key = $data[0]."_".$data[1];
	my ($geno,$id) = (split/:/,$data[4])[0,-1]; 
	if($geno eq "0|1"){
		$genoB = $data[2]."|".$data[3];
	}else{
		$genoB = $data[3]."|".$data[2];
	}
	$PBWHdb{$key} = $geno.":".$genoB.":".$id;
}
close IN;

my %block_dir = ();
open(IN, "tmp.hapVarPB.txt") or die"";
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
#open(OUT, "> switch_error.stat") or die"";
#print OUT "BLOCK-ID	No_of_SNP	No_of_switchedSNP	Error_rate(%)\n";
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
#	print OUT "$bid	$Num_t	$Num_e	$erate\n";
	if($Num_1>$Num_0){
		$block_dir{$bid}->{'Direction'} = "-";
	}else{
		$block_dir{$bid}->{'Direction'} = "+";
	}
}
#close OUT;

my %truedb;
open(OUT, "> true.dataset.txt") or die"";
open(IN, "tmp.hapVarPB.txt") or die"";
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
	next if($geno ne $tmpdb[0]);
	$truedb{$key}++;
}
close IN;

open(IN, $ARGV[0]) or die"";
while(<IN>){
	chomp;
	my ($chrn,$posi) = (split/\s+/,$_)[0,1];
	my $key = $chrn."_".$posi;
	print OUT "$_\n" if(exists($truedb{$key}));
}
close IN;
close OUT;

system("rm tmp.hapVarPB.txt");


