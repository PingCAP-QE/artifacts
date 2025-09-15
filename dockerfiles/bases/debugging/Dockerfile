ARG PINGCAP_BASE
FROM $PINGCAP_BASE

# Install packages with package manager.
RUN --mount=type=cache,id=dnf-cache,target=/var/cache/dnf \
    dnf install -y epel-release && \
    # 🔧 General System Inspection: procps-ng htop iotop atop dstat lsof perf
    dnf install -y procps-ng htop iotop atop dstat lsof  perf && \
    # 🖥 CPU & Performance
    dnf install -y sysstat stress && \
    # 💾 Memory
    dnf install -y smem numactl valgrind && \
    # 📀 Disk / IO
    dnf install -y blktrace fio && \
    # 🌐 Network
    dnf install -y iftop nethogs net-tools tcpdump iperf3 bind-utils ethtool traceroute mtr && \
    # 🐛 Debugging / Tracing
    dnf install -y  gdb bpftrace bcc strace ltrace && \
    # 🧰 Useful Misc
    dnf install -y file vim-common jq nmap-ncat socat tmux ripgrep

# Install addition perf-tools
ADD --chmod=755 https://raw.githubusercontent.com/brendangregg/perf-tools/master/iosnoop /usr/local/bin/
