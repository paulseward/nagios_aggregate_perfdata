#!/usr/bin/perl -wT
# nagios: -epn
#
# Nagios plugin to aggregate perfdata from multiple checks so we can draw a unified graph of activity
# across several servers.
#
# This check should be run on a nagios server (not via nrpe) as it pulls information directly from status.dat
#
#
# Usage:
# check_aggregate_perfdata.pl
#   -H|host-regex           Host regex to match (optional, if missing it will aggregate accross all hosts)
#   -s|service-description  Nagios service description to match (required)
#   -p|perf-label           Perfdata label to aggregate (required)
#   -f|status-file          Path to Nagios status.dat file (defaults to /var/log/nagios/status.dat)
#   -u|units                Units of result (defaults to no units)
#   -w|warning              Warning threshold (optional)
#   -c|critical             Critical threshold (optional)
#   -a|average              Average the results rather than summing them

use strict;
use Data::Dumper;
use Getopt::Long;

# Defaults
my $status_dat = "/var/log/nagios/status.dat";
my $hostmatch  = "";
my $perf_label = "";
my $service_description = "";
my $units = "";
my $warning = 0;
my $critical = 0;
my $average;

# Parse Options
unless (GetOptions (
  "H|host-regex=s" => \$hostmatch,
  "s|service-description=s" => \$service_description,
  "p|perf-label=s"          => \$perf_label,
  "f|status-file=s"         => \$status_dat,
  "u|units=s"               => \$units,
  "w|warning=f"             => \$warning,
  "c|critical=f"            => \$critical,
  "a|average"               => \$average
  )) {
  &quit('UNKNOWN',"Unable to parse command line arguments");
}

# Abort if we're missing reuired parameters
unless ($service_description) {
  &quit('UNKNOWN',"service-description must be specified");
}
unless ($perf_label) {
  &quit('UNKNOWN',"perf-label must be specified");
}

# Parse $status_dat looking for all the servicestatus{} blocks and build an array of hashrefs describing each servicestatus
my $fh = undef;
unless (open($fh, "<", $status_dat)) {
  &quit('UNKNOWN',"Unable to open $status_dat for reading");
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
      # If this servicestatus was for a host/service we're interested in, add it to the array
      if ($$this_status{'host_name'} =~ qr/$hostmatch/) {
        if ($$this_status{'service_description'} =~ qr/$service_description/) {
          push @servicestatus, $this_status;
        }
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

# If we found performance data, process it
if (scalar @servicestatus >= 1) {
  my $aggregate;
  foreach my $status(@servicestatus) {
    if($$status{'performance_data'} =~ qr/^['"]?$perf_label['"]?=(\d+(?:\.\d+)?).*$/) {
      $aggregate += $1;
    }
  }
  # Are we working on sum or average?
  my $rv = defined($average) ? $aggregate / scalar(@servicestatus) : $aggregate;
  my $av_txt = defined($average) ? "average" : "total";
  
  # produce output
  if ($critical) {
    if ($rv >= $critical) {
      &quit('CRITICAL',"$service_description $av_txt CRITICAL|$perf_label=$rv$units;$warning;$critical;;");
    }
  }
  if ($warning) {
    if ($rv >= $warning) {
      &quit('WARNING',"$service_description $av_txt WARNING|$perf_label=$rv$units;$warning;$critical;;");
    }
  }
  # If we're not critical or warning, we're OK
  &quit('OK',"$service_description $av_txt OK|$perf_label=$rv$units;$warning;$critical;;");
}
else {
  # Nothing in the array, bail out with a warning
  &quit('UNKNOWN',"Unable to find matching perfdata for that host/service/label");
}

exit;

sub quit {
  my $level = shift;
  my $text  = shift;
  
  # Nagios error codes
  my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

  if ($level eq "OK") {
    print "OK:$text";
    exit $ERRORS{'OK'};
  }
  elsif ($level eq "WARNING") {
    print "WARNING:$text";
    exit $ERRORS{'WARNING'};
  }
  elsif ($level eq "CRITICAL") {
    print "CRITICAL:$text";
    exit $ERRORS{'CRITICAL'};
  }
  elsif ($level eq "UNKNOWN") {
    print "UNKNOWN:$text";
    exit $ERRORS{'UNKNOWN'};
  }
  elsif ($level eq "DEPENDENT") {
    print "OK:$text";
    exit $ERRORS{'OK'};
  }
  else {
    print "UNKNOWN:Unexpected error level in quit. $level $text";
    exit $ERRORS{'UNKNOWN'};
  }
}
