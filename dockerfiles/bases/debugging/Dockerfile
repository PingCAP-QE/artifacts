ARG PINGCAP_BASE
FROM $PINGCAP_BASE

# Install packages with package manager.
RUN --mount=type=cache,id=dnf-cache,target=/var/cache/dnf \
    dnf install -y epel-release && dnf install -y \
    # 🔧 General System Inspection: procps-ng htop iotop atop dstat lsof perf
    procps-ng htop iotop atop dstat lsof  perf \
    # 🖥 CPU & Performance
    sysstat stress \
    # 💾 Memory
    smem numactl valgrind \
    # 📀 Disk / IO
    blktrace fio \
    # 🌐 Network
    iftop nethogs net-tools tcpdump iperf3 bind-utils ethtool traceroute mtr \
    # 🐛 Debugging / Tracing
    gdb bpftrace bcc strace ltrace \
    # 🧰 Useful Misc
    file vim-common jq nmap-ncat socat tmux ripgrep

# Install addition perf-tools into /opt/perf-tools folder.
RUN curl -L https://github.com/brendangregg/perf-tools/archive/refs/heads/master.tar.gz | tar -xz -C /opt && \
    mv /opt/perf-tools-master /opt/perf-tools
