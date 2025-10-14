ARG PINGCAP_BASE
FROM $PINGCAP_BASE

# Install packages with package manager.
RUN --mount=type=cache,id=dnf-cache,target=/var/cache/dnf \
    dnf install --setopt=install_weak_deps=False --setopt=tsflags=nodocs -y epel-release && \
    dnf install --setopt=install_weak_deps=False --setopt=tsflags=nodocs -y \
    # 🔧 General System Inspection: procps-ng htop iotop atop dstat lsof perf
    atop dstat htop iotop lsof perf procps-ng \
    # 🖥 CPU & Performance
    stress sysstat \
    # 💾 Memory
    numactl smem valgrind \
    # 📀 Disk / IO
    blktrace fio \
    # 🌐 Network
    bind-utils ethtool iftop iperf3 mtr net-tools nethogs tcpdump traceroute wget \
    # 🐛 Debugging / Tracing
    bcc bpftrace gdb ltrace strace \
    # 🧰 Useful Misc
    file jq nmap-ncat ripgrep socat tmux unzip vim-common

# Install addition perf-tools into /opt/perf-tools folder.
RUN curl -L https://github.com/brendangregg/perf-tools/archive/refs/heads/master.tar.gz | tar -xz -C /opt && \
    mv /opt/perf-tools-master /opt/perf-tools

# install tools: mok
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    wget -q -O /tmp/mok.zip https://github.com/oh-my-tidb/mok/releases/download/v0.8/mok-v0.8-linux-${ARCH}.zip && \
    unzip -p /tmp/mok.zip mok-v0.8-linux-${ARCH}/mok > /usr/local/bin/mok && \
    chmod 755 /usr/local/bin/mok && \
    rm -f /tmp/mok.zip

# install tools: tiup
# renovate: datasource=github-release depName=pingcap/tiup
ARG TIUP_VER=v1.16.3
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    wget -q -O - https://tiup-mirrors.pingcap.com/tiup-${TIUP_VER}-${OS}-${ARCH}.tar.gz | tar -zxvf - -C /usr/local/bin && \
    chmod 755 /usr/local/bin/tiup && \
    mkdir -p "$HOME/.tiup/bin" && \
    tiup mirror set --reset
