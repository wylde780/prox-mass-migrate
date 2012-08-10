#!/usr/bin/perl
##Purpose of this is to automatically move all vm's to another node so that this one can reboot
use Data::Dumper;
chomp($src_mig = $ARGV[0]);
chomp($dst_mig = $ARGV[1]);
$logfile = 'migrate-all.log';
chomp($date = `date +"%b %d %T"`);
if($ARGV[2] =~ m/\-d/ )
{
	open LOGFILE, ">>$logfile" or die "Can't open $logfile\n";
	print LOGFILE "$date -> Starting to migrate\n";
}	
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
#print @storage;
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
				print LOGFILE "$date -> ***VMID -> $vmlist{$x}{vmid}\nHostname -> $vmlist{$x}{hostname} "
					. "Disk -> $tmp[1] has a local disk and has been removed from the migration list***\n";
				delete($vmlist{$x});
			}
		}
	}
&migrate(%vmlist);	
}#End CheckDisk 
sub migrate()
{
	#Do Stuff
	for ($x = 0; $x<scalar(keys %vmlist); $x++)
	{
		if(defined($vmlist{$x}{hostname}))
		{
#This if tests only my stuff
			if ($vmlist{$x}{vmid} eq "201" || $vmlist{$x}{vmid} eq "203" || $vmlist{$x}{vmid} eq "209")
#			if ($vmlist{$x}{vmid} eq "209")
			{
				chomp(@migrate = `ssh $src_mig qm migrate $vmlist{$x}{vmid} $dst_mig --online`);
				print "$date -> $x -> $vmlist{$x}{vmid}, $vmlist{$x}{hostname} $src_mig -> $dst_mig\n";
				&stats(@migrate)
			}
		}
	}
}
#print Dumper %vmlist;
sub stats()
{
	for($x=0; $x<@migrate; $x++)
	{
		if($migrate[$x] =~ m/status/)
		{
			chomp($status = $migrate[$x]);
			@tmp = split(/ /, $status);
			$status = $tmp[-1];
			@tmp = ();
		}
		if($migrate[$x] =~ m/speed/)
		{
			chomp($speed = $migrate[$x]);
			@tmp = split(/ /, $speed);
			$speed = "$tmp[-2]$tmp[-1]";
			@tmp = ();
		}
		if($migrate[$x] =~ m/finished/)
		{
			#Aug 10 02:36:14 migration finished successfuly duration 00:00:08
			chomp($finished = $migrate[$x]);
			$finished =~ s/(\)|\()//g;
			@tmp = split(/ /, $finished);
			$finished = $tmp[-1];
			@tmp = ();
		}
	}
	print LOGFILE "$date -> Debugging Stats\nMigration $status at a rate of $speed in $finished\n";
}#end stats
if(defined($ARGV[2]))
{ 
	print LOGFILE "$date -> Exiting\n";
	CLOSE(LOGFILE);
}
