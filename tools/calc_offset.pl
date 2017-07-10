#!/usr/bin/perl -w


open ( FILE, "obj/kc85/HeaderKC.map" ) || die "can't open file!";
@lines = <FILE>;
close (FILE);
$found=0;
$base=0;
foreach $line (@lines) {
    if ($line =~ m/^[ ]*([0-9a-fA-F]+)[ ]*end_of_ram(.*)/ ) { $found=$1; }
    if ($line =~ m/^[ ]*([0-9a-fA-F]+)[ ]*s__KCC_HEADER(.*)/ ) { $base=$1; }
}

$newEnd="8000";
printf "new:%s found:%s base:%s\n",$newEnd,$found,$base;

printf "-b _KCC_HEADER=0x%x -b _CODE=0x%x\n",hex($newEnd)-hex($found)+hex($base),hex($newEnd)-hex($found)+hex($base)+128;

