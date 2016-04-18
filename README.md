# nagios_aggregate_perfdata

Nagios plugin to aggregate perfdata from multiple checks so we can draw a unified graph of activity across several servers.

This check should be run on a nagios server (not via nrpe) as it pulls information directly from status.dat

```
Usage:
check_aggregate_perfdata.pl
  -H|host-regex           Host regex to match (optional, if missing it will aggregate accross all hosts)
  -s|service-description  Nagios service description to match (required)
  -p|perf-label           Perfdata label to aggregate (required)
  -f|status-file          Path to Nagios status.dat file (defaults to /var/log/nagios/status.dat)
  -u|units                Units of result (defaults to no units)
  -w|warning              Warning threshold (optional)
  -c|critical             Critical threshold (optional)
  -a|average              Average the results rather than summing them
```
