#!/usr/bin/env bash

set -euo pipefail

setup_geoblock() {
    info "Setting up GeoBlock"

    doas install -Dm755 -C \
        "$LIBEXEC_DIR/security/geoblock-update" \
        /usr/local/libexec/geoblock-update

    doas install -Dm644 -C \
        "$CONFIG_DIR/system/systemd/geoblock/geoblock-update.service" \
        /etc/systemd/system/geoblock-update.service

    doas install -Dm644 -C \
        "$CONFIG_DIR/system/systemd/geoblock/geoblock-update.timer" \
        /etc/systemd/system/geoblock-update.timer

    doas systemctl daemon-reload
    sleep 3
    doas systemctl restart geoblock-update.service
    doas systemctl enable --now geoblock-update.timer

    success "GeoBlock configured"
}

setup_nftables() {
    info "Setting up nftables"

    doas install -Dm644 -C \
        "$CONFIG_DIR/system/network/nftables/base-firewall.nft" \
        /etc/nftables/base-firewall.nft

    local includes=(
        "/etc/nftables/base-firewall.nft"
        "/etc/nftables/geoblock.nft"
    )

    for f in "${includes[@]}"; do
        local line="include \"$f\""
        doas grep -qxF "$line" /etc/sysconfig/nftables.conf || \
            echo "$line" | doas tee -a /etc/sysconfig/nftables.conf >/dev/null
    done

    # We no longer need firewalld so remove it
    doas systemctl disable --now firewalld.service
    remove_packages firewalld*

    # Removing firewalld also removes nftables packages, so reinstall nftables.   
    install_packages nftables nftables-services

    # Load base firewall and GeoBlock rules.
    doas systemctl enable --now nftables.service

    success "nftables configured and loaded"
}

setup_hagezi_blocklist() {
    info "Setting up HaGeZi DNS blocklists"

    install_packages curl
 
    doas mkdir -p /etc/dnsmasq.d/

    # Install independent updater.
    doas install -Dm755 -C \
        "$LIBEXEC_DIR/security/hagezi-update" \
        /usr/local/libexec/hagezi-update

    # Install systemd units.
    doas install -Dm644 -C \
        "$CONFIG_DIR/system/systemd/hagezi/hagezi-update.service" \
        /etc/systemd/system/hagezi-update.service

    doas install -Dm644 -C \
        "$CONFIG_DIR/system/systemd/hagezi/hagezi-update.timer" \
        /etc/systemd/system/hagezi-update.timer

    doas systemctl daemon-reload
    doas systemctl start hagezi-update.service
    doas systemctl enable --now hagezi-update.timer

    success "HaGeZi DNS blocklists configured"
}

setup_unbound() {
    info "Setting up Unbound DNS forwarder"

    install_packages unbound

    # Install Unbound configuration.
    doas install -Dm644 -C \
        "$CONFIG_DIR/system/network/unbound/unbound.conf" \
        /etc/unbound/unbound.conf

    # Install systemd socket and service hardening.
    doas install -Dm644 -C \
        "$CONFIG_DIR/system/systemd/unbound/unbound.socket" \
        /etc/systemd/system/unbound.socket

    doas install -Dm644 -C \
        "$CONFIG_DIR/system/systemd/unbound/hardening.conf" \
        /etc/systemd/system/unbound.service.d/hardening.conf

    # Configure SELinux for Unbound's custom DNS port.
    install_packages policycoreutils-python-utils

    doas semanage port -a -t dns_port_t -p tcp 5353
    doas semanage port -a -t dns_port_t -p udp 5353

    doas systemctl daemon-reload

    doas unbound-checkconf /etc/unbound/unbound.conf

    doas systemctl enable --now unbound.socket

    success "Unbound DNS forwarder configured"
}

setup_dnsmasq() {
    info "Configuring dnsmasq"

    install_packages dnsmasq curl

    # Configure NetworkManager dns to none.
    doas install -Dm644 /dev/stdin \
        /etc/NetworkManager/conf.d/00-use-dnsmasq.conf <<'EOF'
[main]
dns=none
EOF

    doas rm -rf /etc/resolv.conf
    echo "nameserver 127.0.0.1" | doas tee /etc/resolv.conf
    doas chmod 644 /etc/resolv.conf

    # Forward dnsmasq queries to Unbound.
    doas install -Dm644 /dev/stdin \
        /etc/dnsmasq.conf <<'EOF'
listen-address=127.0.0.1
port=53
no-resolv
cache-size=10000
server=127.0.0.1#5353
conf-dir=/etc/dnsmasq.d/,*.conf
EOF

    doas systemctl enable --now dnsmasq.service

    success "dnsmasq configured"
}

setup_harden_network() {
    [[ "$(cat /proc/1/comm)" == "systemd" ]] || return 0

    info "Applying network hardening"

    setup_geoblock
    setup_nftables

    setup_unbound
    setup_dnsmasq

    setup_hagezi_blocklist

    success "Network hardening complete"
}
