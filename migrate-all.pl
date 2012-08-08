#!/usr/bin/perl
##Purpose of this is to automatically move all vm's to another node so that this one can reboot
use Data::Dumper;
chomp($src_mig = $ARGV[0]);
chomp($dst_mig = $ARGV[1]);

#@src_node = `pvesh get /nodes/$ARGV[0] 2>&1`; 
chomp(@src_vms = `ssh $ARGV[0] qm list | grep running`);
chomp(@storage = `pvesh get /storage 2>&1 | grep storage`);
for($x=0; $x<@storage; $x++)
{
	if($storage[$x] =~ m/local/) 
	{
		splice @storage, $x, 1;
	}	
}
print @storage;
%vmlist =();
$count = 0;
foreach(@src_vms)
{
	$_ =~ s/ +/,/g; 
	$_ =~ s/ /,/g; 
	$_ =~ s/^,//;
	@tmp = split(",",$_);	
	$vmlist{$count}{"vmid"} = $tmp[0];
	$vmlist{$count}{"max-mem"} = $tmp[3];
	$vmlist{$count}{"disk"} = $tmp[-1];
	$vmlist{$count}{"hostname"} = $tmp[1];
	$count++;
	@tmp = ();
}
&CheckDisk;
sub CheckDisk()
{
	for ($x = 0; $x<scalar(keys %vmlist); $x++)
	{
		$conf = "/etc/pve/qemu-server/$vmlist{$x}{vmid}.conf";
		@conf = `ssh $src_mig cat $conf`;
		foreach(@conf)
		{
			if(/local:/)
			{
				chomp(@tmp = split('\/', $_));
				print "VMID -> $vmlist{$x}{vmid}\nHostname -> $vmlist{$x}{hostname}\n"
					. "Disk -> $tmp[1]\n"
					. "has a local disk and has been removed from the migration list\n";
				delete($vmlist{$x});
			}
#			if(
		}
	}
&migrate(@migrate);	
}#End CheckDisk 
sub migrate()
{
	#Do Stuff
	foreach(@migrate)
	{
		print "$x Migrating $_ from $src_mig -> $dst_mig\n";
		
	}
}
#print Dumper %vmlist;
$blah = @migrate;
print $blah;
