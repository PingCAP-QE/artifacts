ARG PINGCAP_BASE
FROM $PINGCAP_BASE

# 📄 Core text / navigation tools: ripgrep
# 🔧 General System Inspection: procps-ng htop iotop atop dstat lsof strace perf
RUN --mount=type=cache,id=dnf-cache,target=/var/cache/dnf \
    dnf install -y epel-release && \
    dnf install -y \
    ripgrep
# procps-ng htop iotop atop dstat lsof strace perf

### 🖥 **CPU & Performance**

# * `mpstat` (from `sysstat`) → per-CPU utilization
# * `pidstat` → per-process CPU, memory, IO
# * `stress` or `stress-ng` → load generator for CPU/memory/disk/network
# * `perf-tools` (e.g., `funccount`, `execsnoop`) → deeper kernel/CPU tracing


### 💾 **Memory**

# * `free` → quick memory usage
# * `smem` → memory usage per process with shared memory reporting
# * `pmap` → process memory map
# * `numastat` → NUMA memory stats
# * `valgrind` (optional, heavy) → memory debugging / leaks (useful for dev builds)


### 📀 **Disk / IO**

# * `iotop` → IO usage
# * `iostat` (from `sysstat`) → block device IO
# * `blktrace` + `blkparse` → detailed block-level tracing
# * `fio` → flexible IO workload generator
# * `dd` → quick read/write speed tests
# * `lsblk`, `df`, `du` → disk layout and usage


### 🌐 **Network**

# * `iftop` → live network usage per connection
# * `nethogs` → per-process bandwidth
# * `ss` / `netstat` → socket statistics
# * `tcpdump` → packet capture
# * `iperf3` → network throughput testing
# * `dig`, `curl`, `wget` → DNS/HTTP testing
# * `ethtool` → NIC statistics
# * `traceroute`, `mtr` → path and latency diagnostics

### 🐛 **Debugging / Tracing**

# * `gdb` → debugger
# * `bpftrace` / `bcc` tools (if kernel supports it) → powerful tracing
# * `strace` / `ltrace` → syscall and library call tracing

### 🧰 **Useful Misc**

# * `busybox` → Swiss army knife for small utilities
# * `file` → check file types
# * `hexdump` / `xxd` → binary inspection
# * `jq` → JSON parser (for logs and configs)
# * `nc` / `socat` → networking testing
# * `tmux` → for long-running debug sessions inside container


### 🏢 **Company Tools**
# * TiUp

# if you want tidb-ctl, pd-ctl, tikv-ctl tool, you can install them with tiup tool:
# tiup tidb-ctl ...

# mok / tiup  / rg /
