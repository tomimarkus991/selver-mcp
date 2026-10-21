#!/bin/bash
# Outbound allowlist: the container may only talk to Selver, Claude and the npm registry.
# Re-run (sudo /usr/local/bin/init-firewall.sh) if a site's IPs change.
set -euo pipefail

ALLOWED_DOMAINS=(
  # Selver shop + Smart-ID SSO (used by scripts/selver_auth.py)
  selver.ee
  www.selver.ee
  sso.partnerkaart.ee
  consent.cookiebot.com
  consentcdn.cookiebot.com
  # Claude Code
  api.anthropic.com
  claude.ai
  platform.claude.com
  console.anthropic.com
  statsig.anthropic.com
  sentry.io
  # bun install
  registry.npmjs.org
)

# Reset filter table only (nat holds Docker's internal DNS rules)
iptables -F
iptables -X
ipset destroy allowed-domains 2>/dev/null || true
ipset create allowed-domains hash:net

for domain in "${ALLOWED_DOMAINS[@]}"; do
  ips=$(dig +short A "$domain" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || true)
  if [ -z "$ips" ]; then
    echo "WARN: could not resolve $domain"
    continue
  fi
  for ip in $ips; do
    ipset add allowed-domains "$ip" -exist
  done
done

HOST_NET=$(ip route | awk '/default/ {print $3}' | sed 's/\.[0-9]*$/.0\/24/')

iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -s "$HOST_NET" -j ACCEPT
iptables -A OUTPUT -d "$HOST_NET" -j ACCEPT
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# No IPv6 at all, so it can't be used to go around the allowlist
ip6tables -P INPUT DROP 2>/dev/null || true
ip6tables -P OUTPUT DROP 2>/dev/null || true
ip6tables -P FORWARD DROP 2>/dev/null || true

# Verify
if curl -s --connect-timeout 5 https://example.com >/dev/null; then
  echo "ERROR: firewall check failed, example.com is reachable"
  exit 1
fi
if ! curl -s --connect-timeout 5 -o /dev/null https://www.selver.ee; then
  echo "ERROR: firewall check failed, www.selver.ee is blocked"
  exit 1
fi
echo "Firewall OK: example.com blocked, www.selver.ee reachable"
