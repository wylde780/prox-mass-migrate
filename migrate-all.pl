#!/usr/bin/perl
##Purpose of this is to automatically move all vm's to another node so that this one can reboot
use Data::Dumper;
chomp($src_mig = $ARGV[0]);
chomp($dst_mig = $ARGV[1]);
$logfile = 'migrate-all.log';
if($ARGV[2] =~ m/\-d/ )
{
	open LOGFILE, ">>$logfile" or die "Can't open $logfile\n";
	print LOGFILE "$date -> Starting to migrate\n";
}	
chomp(@src_vms = `ssh $ARGV[0] qm list | grep running`);
chomp(@storage = `pvesh get /storage 2>&1 | grep storage`);
for($x=0; $x<@storage; $x++)
{
	if($storage[$x] =~ m/local/) 
	{
		splice @storage, $x, 1;
	}	
}
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
	chomp($date = `date +'%b %d %T'`);
	for ($x = 0; $x<scalar(keys %vmlist); $x++)
	{
		$conf = "/etc/pve/qemu-server/$vmlist{$x}{vmid}.conf";
		@conf = `ssh $src_mig cat $conf`;
		foreach(@conf)
		{
			if(/local:/)
			{
				chomp(@tmp = split('\/', $_));
				print LOGFILE "$date -> *** $vmlist{$x}{vmid} "
					. "has a local disk ($tmp[1]) and has been removed from the migration list ***\n";
				print "$vmlist{$x}{vmid} has been excluded due to having a local disk\n";
				delete($vmlist{$x});
			}
		}
	}
&migrate(%vmlist);	
}#End CheckDisk 
sub migrate()
{
	chomp($date = `date +'%b %d %T'`);
	print LOGFILE "Debugging Stats\n";
	for ($x = 0; $x<scalar(keys %vmlist); $x++)
	{
		if(defined($vmlist{$x}{hostname}))
		{
			chomp(@migrate = `ssh $src_mig qm migrate $vmlist{$x}{vmid} $dst_mig --online`);
			print LOGFILE "$date -> $vmlist{$x}{vmid}, $vmlist{$x}{hostname} from $src_mig to $dst_mig\n";
			print "Migrated $vmlist{$x}{vmid} from $src_mig -> $dst_mig\n";
			&stats(@migrate);
		}
	}
}
sub stats()
{
	chomp($date = `date +'%b %d %T'`);
	foreach(@migrate)
	{
		if(/status/)
		{
			chomp($status = $_);
			@tmp = split(/ /, $status);
			$status = $tmp[-1];
			@tmp = ();
		}
		if(/speed/)
		{
			chomp($speed = $_);
			@tmp = split(/ /, $speed);
			$speed = "$tmp[-2]$tmp[-1]";
			@tmp = ();
		}
		if(/finished/)
		{
			chomp($finished = $_);
			$finished =~ s/(\)|\()//g;
			@tmp = split(/ /, $finished);
			$finished = $tmp[-1];
			@tmp = ();
		}
	}
	undef @migrate;
	print LOGFILE "$date Migration $status at a rate of $speed in $finished\n";
}#end stats
if(defined($ARGV[2]))
{ 
	print LOGFILE "$date -> Exiting\n";
	CLOSE(LOGFILE);
}
