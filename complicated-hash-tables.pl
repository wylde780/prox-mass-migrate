#!/usr/bin/perl
##Purpose of this is to automatically move all vm's to another node so that this one can reboot
use Data::Dumper;
$src_mig = $ARGV[0];
$dst_mig = $ARGV[1];
chomp(@nodes = `pvecm nodes`);
chomp(@vms = `qm list | grep running`);
#$count;

&GetNODEs;
#   1   M      4   2012-07-22 04:44:48  lisa
#1:M:4:2012-07-22:04:44:48:lisa
sub GetNODEs 
{
	$count = 0;
	shift(@nodes);
	foreach(@nodes)
	{
                $_ =~ s/ +/,/g;
                $_ =~ s/ /,/g;
                $_ =~ s/^,//;
		push(@temp,$_);
	}	
	foreach(@temp)
	{
		##1:M:4:2012-07-22:04:44:48:lisa
		#%nodes = ();		
		@tmp = split(",",$_);
		$nodes{$count}{name} = $tmp[-1];
		$nodes{$count}{id} = $tmp[0];
	 	$count++;
	}
##Hash debugging
#print Dumper %nodes;
print "Hash Tables are working $nodes{2}{name}\n";
}#End GetNODEs

#       101 jays-box             running    2048              32.00 766536    
sub GetVMs
{
        foreach(@vms)
        {
		@tmp = ();
                $_ =~ s/ +/:/g;
                $_ =~ s/ /:/g;
                $_ =~ s/^://;
		push(@tmp, $_);
	}
	foreach(@tmp)
	{
		
	}

}#End GetVMs

	
