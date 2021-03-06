[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4780668.svg)](https://doi.org/10.5281/zenodo.4780668)


# calc_switchErr
A switch error indicates that a single base that is suppose to be present in one haplotype is incorrectly anchored onto another. This kind of assembly errors is likely prevalent in the haplotype-resolved genome assembly. To detect the switch errors in the phased chromosome-scale genome assembly, we developed a novel pipeline (calc_switchErr), relying on a ‘truely’ phased SNP dataset, which can be generated by incorporating PacBio long reads and 10 x Genomics Linked reads. The concept of the ‘truely’ phased SNP dataset is to find the consistently phased SNPs in PacBio reads phasing and 10x reads phasing. This pipeline requires several steps with detailed information listed below:


### Choose haplotype A genome from the phased diploid genome as a reference for reads mapping and SNP calling

### SNP calling based on lumina WGS reads
> We prefer to use GATK pipeline with the best practices workflow suggested in the official website (https://gatk.broadinstitute.org/hc/en-us/articles/360036194592-Getting-started-with-GATK4). 

### SNP phasing for PacBio long reads
> a. map PacBio long reads against the reference genome (haplotype A) using minimap2
```
minimap2 -t 20 -ax map-pb --secondary=no reference.fasta pacbio.subreads.fasta.gz |samtools view -bt reference.fasta.fai - |samtools sort -@ 20 -o pb.sorted.bam -
```
> b. SNP phasing for each individual chromosome using whatshap program
```
whatshap phase --ignore-read-groups -o Chr01HA.phased.vcf --reference=reference.fasta --chromosome Chr01HA TGY.illuminaWGS.vcf pb.sorted.bam
whatshap phase --ignore-read-groups -o Chr02HA.phased.vcf --reference=reference.fasta --chromosome Chr01HA TGY.illuminaWGS.vcf pb.sorted.bam
...
whatshap phase --ignore-read-groups -o Chr15HA.phased.vcf --reference=reference.fasta --chromosome Chr15HA TGY.illuminaWGS.vcf pb.sorted.bam
```
> c. extract phased SNP information
```
cat Chr*.phased.vcf|grep -v '#'|grep PS|cut -f1,2,4,5,10 > PB.WH.phase.txt
```
### SNP phasing for 10x Genomics Linked reads
> a. process the 10x Genomics reads using proc10xG pipeline (https://github.com/ucdavis-bioinformatics/proc10xG)
```
python ~/software/proc10xG/process_10xReads.py -a -1 TGY_S1_L001_R1_001.fastq.gz -2 TGY_S1_L001_R2_001.fastq.gz | bwa mem -t 40 -p -C reference.fasta - |python ~/software/proc10xG/samConcat2Tag.py |samtools sort -@ 24 -o 10x.sorted.bam - 2>stderr.out > stdout.out
samtools index 10x.sorted.bam
```
> b. Whatshap phasing of 10x Genomics Linked reads
```
whatshap phase --ignore-read-groups -o Chr01HA.phased.vcf --reference=reference.fasta --chromosome Chr01HA TGY.illuminaWGS.vcf 10x.sorted.bam
whatshap phase --ignore-read-groups -o Chr02HA.phased.vcf --reference=reference.fasta --chromosome Chr01HA TGY.illuminaWGS.vcf 10x.sorted.bam
...
whatshap phase --ignore-read-groups -o Chr15HA.phased.vcf --reference=reference.fasta --chromosome Chr15HA TGY.illuminaWGS.vcf 10x.sorted.bam
```
> c. extract phased SNP information
```
cat Chr*.phased.vcf|grep -v '#'|grep PS|cut -f1,2,4,5,10 > 10x.WH.phase.txt
```

### Extract consistently phased SNPs in Pacbio phaisng and 10x phasing as 'truely' phased SNPs
```
perl getTrueData.pl PB.WH.phase.txt 10x.WH.phase.txt
```
> This script will output a file ```true.dataset.txt```, which can be used to assess the switch errors in ALLHiC phasing

### Identify signatures bewteen the two haplotypes in ALLHiC assembly
> a. separate the homologous chromosomes for comparison using ```splitChrbyFa.pl```(https://github.com/tangerzhang/my_script/blob/master/splitChrByFa.pl)
```
perl splitChrByFa.pl haplotype-resoved.genome.assembly.fasta
```
> b. comparison of haplotype B to haplotype A for each homologous chromosome group
```
nucmer --mum -l 1000 -c 200 -g 200 -t 12 -p Chr01 Chr01HA.fasta Chr01HB.fasta && show-snps -Clr Chr01.delta > Chr01.snps
nucmer --mum -l 1000 -c 200 -g 200 -t 12 -p Chr02 Chr02HA.fasta Chr02HB.fasta && show-snps -Clr Chr02.delta > Chr02.snps
...
nucmer --mum -l 1000 -c 200 -g 200 -t 12 -p Chr15 Chr15HA.fasta Chr15HB.fasta && show-snps -Clr Chr15.delta > Chr15.snps
```
> c. format the SNP information for the switch error evluation
```
cat Chr*.snps |grep Chr |grep -v home|perl -e 'while(<>){chomp;$_=~s/^\s+//;@t=split(/\s+/,$_);print "$t[13]\t$t[0]\t$t[1]\t$t[13]\t$t[3]\t$t[2]\n" if($t[1] ne "." and $t[2] ne ".")}' > ALLHiC.hapVar.snps
```

### Evalution of switch errors in ALLHiC phasing
```
perl calc_swtichErr.pl true.dataset.txt ALLHiC.hapVar.snps
```
> Note: We have provided the testing sample data (10x.WH.phase.txt, PB.WH.phase.txt and ALLHiC.hapVar.snps), which can be download from the following links:  
Baidu cloud: https://pan.baidu.com/s/1FD_CSTTnBax3aOoNdaMHiA  Extraction number: lxnv  
Google drive: https://drive.google.com/drive/folders/1tH7TOV_a41QMVsENoNqznbJcDPPN61GZ?usp=sharing

