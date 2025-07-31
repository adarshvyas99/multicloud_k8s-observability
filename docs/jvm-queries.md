# JVM Metrics Queries for Grafana

## Memory Metrics
```promql
# Heap Memory Usage
jvm_memory_bytes_used{area="heap"}

# Non-Heap Memory Usage  
jvm_memory_bytes_used{area="nonheap"}

# Heap Memory Max
jvm_memory_bytes_max{area="heap"}

# Memory Pool Usage (Eden, Tenured, etc.)
jvm_memory_pool_bytes_used

# Memory Pool by Type
jvm_memory_pool_bytes_used{pool="Eden Space"}
jvm_memory_pool_bytes_used{pool="Tenured Gen"}
```

## Garbage Collection
```promql
# GC Collection Count Rate
rate(jvm_gc_collection_seconds_count[5m])

# GC Time Spent Rate
rate(jvm_gc_collection_seconds_sum[5m])

# GC by Type
rate(jvm_gc_collection_seconds_count{gc="Copy"}[5m])
rate(jvm_gc_collection_seconds_count{gc="MarkSweepCompact"}[5m])
```

## Threading
```promql
# Current Thread Count
jvm_threads_current

# Daemon Threads
jvm_threads_daemon

# Peak Thread Count
jvm_threads_peak

# Thread States
jvm_threads_state
```

## Class Loading
```promql
# Currently Loaded Classes
jvm_classes_currently_loaded

# Total Classes Loaded
jvm_classes_loaded_total

# Classes Unloaded
jvm_classes_unloaded_total
```

## Process Metrics
```promql
# CPU Usage
rate(process_cpu_seconds_total[5m])

# Memory Usage
process_resident_memory_bytes
process_virtual_memory_bytes

# File Descriptors
process_open_fds
process_max_fds
```

## JVM Info
```promql
# JVM Version Info
jvm_info

# JVM Uptime
jvm_uptime_seconds

# JMX Exporter Info
jmx_exporter_build_info
```