FROM oven/bun:1

# System tools: python for the Smart-ID login script, firewall tooling, sudo for the firewall script only
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip \
    git curl ca-certificates sudo \
    iptables ipset dnsutils iproute2 \
    && rm -rf /var/lib/apt/lists/*

# Playwright + Chromium in a shared location so the non-root user can use it
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN pip3 install --break-system-packages playwright \
    && playwright install --with-deps chromium

# Firewall: the bun user may run exactly this script as root, nothing else
COPY init-firewall.sh /usr/local/bin/init-firewall.sh
RUN chmod 755 /usr/local/bin/init-firewall.sh \
    && echo "bun ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/firewall \
    && chmod 0440 /etc/sudoers.d/firewall

# Claude Code (native installer), config kept in a volume so login survives rebuilds
USER bun
ENV CLAUDE_CONFIG_DIR=/home/bun/.claude \
    DISABLE_AUTOUPDATER=1 \
    PATH=/home/bun/.local/bin:$PATH
RUN mkdir -p /home/bun/.claude \
    && curl -fsSL https://claude.ai/install.sh | bash
