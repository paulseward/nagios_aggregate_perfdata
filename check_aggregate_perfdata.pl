#!/usr/bin/perl -wT
# nagios: -epn
#
# Nagios plugin to aggregate perfdata from multiple checks so we can draw a unified graph of activity
# across several servers.
#
# This check should be run on a nagios server (not via nrpe) as it pulls information directly from status.dat
#
#
# %options = (
#    "H|host-regex=s"            => [ \$host_regex2,  "Host regex to match (optional)" ],
#    "s|service-description=s"   => [ \$service_desc, "Nagios service description to cluster together" ],
#    "p|perf-label=s"            => [ \$perf_label,   "Perfdata label to aggregate in perfdata" ],
#    "f|status-file=s"           => [ \$status_dat,   "Nagios status.dat file to check for the aggregate perfdata (defaults to $default_status_dat)" ],
#    "u|units=s"                 => [ \$units,        "Units of perfdata" ],
#    "w|warning=s"               => [ \$warning,      "Warning threshold or ran:ge (inclusive)"   ],
#    "c|critical=s"              => [ \$critical,     "Critical threshold or ran:ge (inclusive)" ],
#    "a|average"                 => [ \$critical,     "Average the results rather than summing them" ],
# );

use strict;
use Data::Dumper;

# Nagios error codes
my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

# Defaults
# my $status_dat = "/var/log/nagios/status.dat";
my $status_dat = "./status.dat";
my $hostmatch  = "137.222.10.3[69]";
my $perf_label = "time";

# Parse Options - TODO

# Parse $status_dat looking for all the servicestatus{} blocks and build an array of hashrefs describing each servicestatus
my $fh = undef;
unless (open($fh, "<", $status_dat)) {
  print "Unable to open $status_dat for reading\n";
  exit $ERRORS{'UNKNOWN'};
}

my @servicestatus;
my $this_status=undef;
my $in_svc_blk = 0;
while(<$fh>){
  # Set a flag to say if we're inside a servicestatus block or not
  if ($_ =~ /^\s*servicestatus\s+{\s*$/) {
    $in_svc_blk = 1;
  }
 
  # If we previously matched the start of a servicestatus block:
  if ($in_svc_blk) {
    # If this is the end of the servicestatus block, process the hashref and reset for the next block
    if (/^\s*}\s*$/) {
      # If this servicestatus was for a host we're interested in, add it to the array
      if ($$this_status{'host_name'} =~ qr/$hostmatch/) {
        push @servicestatus, $this_status;
      }
      $this_status=undef;
      $in_svc_blk = 0;
    }
    else {
      # else, it's a line from within the servicestatus block, stash it and move on
      if (/^\s*([^=]*)\s*=\s*(.*)\s*/) {
        $$this_status{$1}=$2;
      }
    }
  }
}
close($fh);

# If we found performance data, process it - TODO
if (scalar @servicestatus >= 1) {
  my $aggregate;
  foreach my $status(@servicestatus) { # TODO
    if($$status{'performance_data'} =~ qr/^['"]?$perf_label['"]?=(\d+(?:\.\d+)?).*$/) {
      $aggregate += $1;
    }
  }
  # Output the summarized perfdata - TODO
  print "Sum = $aggregate\n";
  print "Average = " . ($aggregate / scalar(@servicestatus)) . "\n";
}
else {
  # Nothing in the array, bail out with a warning
  print "Unable to find any servicestatus detail for that host\n";
  exit $ERRORS{'UNKNOWN'};
}

exit;

__END__
