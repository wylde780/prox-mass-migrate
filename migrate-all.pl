#!/usr/bin/perl
##Purpose of this is to automatically move all vm's to another node so that this one can reboot
use Data::Dumper;
chomp($src_mig = $ARGV[0]);
chomp($dst_mig = $ARGV[1]);

#@src_node = `pvesh get /nodes/$ARGV[0] 2>&1`; 
chomp(@src_vms = `ssh $ARGV[0] qm list | grep running`);
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
			if(/local/)
			{
				#ide0: local:210/vm-210-disk-2.qcow2
				@tmp = split('\/', $_);
				print "VMID -> $vmlist{$x}{vmid}\nHostname -> $vmlist{$x}{hostname}\nhas a local disk "
					. "and has been removed from migration\n";
				print "Match $tmp[1]\n";
				delete($vmlist{$x});
			}
		&migrate;			
		}
	}	
}#End CheckDisk 
sub migrate()
{
	#Do Stuff
}
#print Dumper %vmlist;
