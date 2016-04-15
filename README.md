# nagios_aggregate_perfdata

Nagios plugin to aggregate perfdata from multiple checks so we can draw a unified graph of activity across several servers.

This check should be run on a nagios server (not via nrpe) as it pulls information directly from status.dat

```
Usage:
  check_aggregate_perfdata.pl 
    -H|host-regex           Host regex to match (optional, if it's missing it will aggregate accross all hosts)
    -s|service-description  Nagios service description to match
    -p|perf-label           Perfdata label to aggregate
    -f|status-file          Path to Nagios status.dat file
    -u|units                Units of result
    -w|warning              Warning threshold
    -c|critical             Critical threshold
    -a|average              Average the results rather than summing them
```
