#!/usr/bin/env bash

set -euo pipefail

setup_nftables() {
    info "Setting up nftables"

    install_packages nftables nftables-services

    # Install base firewall rules.
    doas install -Dm644 -C \
        "$CONFIG_DIR/system/network/nftables/base-firewall.nft" \
        /etc/nftables/base-firewall.nft

    # Include base firewall rules.
    doas grep -qxF 'include "/etc/nftables/base-firewall.nft"' \
        /etc/sysconfig/nftables.conf || \
        echo 'include "/etc/nftables/base-firewall.nft"' |
            doas tee -a /etc/sysconfig/nftables.conf >/dev/null

    # Include GeoBlock rules.
    doas grep -qxF 'include "/etc/nftables/geoblock.nft"' \
        /etc/sysconfig/nftables.conf || \
        echo 'include "/etc/nftables/geoblock.nft"' |
            doas tee -a /etc/sysconfig/nftables.conf >/dev/null

    success "nftables configured"
}

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

setup_hagezi_blocklist() {
    info "Setting up HaGeZi DNS blocklists"

    install_packages dnsmasq curl

    # Configure NetworkManager to use dnsmasq.
    doas install -Dm644 /dev/stdin \
        /etc/NetworkManager/conf.d/00-use-dnsmasq.conf <<'EOF'
[main]
dns=dnsmasq
EOF

    doas install -d -m 755 /etc/NetworkManager/dnsmasq.d

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

    # Forward dnsmasq queries to Unbound.
    doas install -Dm644 /dev/stdin \
        /etc/NetworkManager/dnsmasq.d/upstream.conf <<'EOF'
no-resolv
server=127.0.0.1#5353
EOF

    # Configure SELinux for Unbound's custom DNS port.
    doas semanage port -a -t dns_port_t -p tcp 5353
    doas semanage port -a -t dns_port_t -p udp 5353

    doas systemctl daemon-reload

    doas unbound-checkconf /etc/unbound/unbound.conf

    doas systemctl enable --now unbound.socket

    doas systemctl restart NetworkManager

    success "Unbound DNS forwarder configured"
}

configure_network_dns() {
    info "Configuring NetworkManager DNS priorities"

    local uuid type

    while IFS=: read -r uuid type; do
        case "$type" in
            802-3-ethernet|802-11-wireless)
                doas nmcli connection modify "$uuid" \
                    ipv4.dns "" \
                    ipv6.dns "" \
                    ipv4.ignore-auto-dns yes \
                    ipv6.ignore-auto-dns yes \
                    ipv4.dns-priority -100 \
                    ipv6.dns-priority -100
                ;;

            wireguard)
                doas nmcli connection modify "$uuid" \
                    ipv4.dns "" \
                    ipv6.dns "" \
                    ipv4.ignore-auto-dns yes \
                    ipv6.ignore-auto-dns yes \
                    ipv4.dns-priority 100 \
                    ipv6.dns-priority 100
                ;;
        esac
    done < <(nmcli -t -f UUID,TYPE connection show --active)

    success "NetworkManager DNS priorities configured"
}

setup_harden_network() {
    [[ "$(cat /proc/1/comm)" == "systemd" ]] || return 0

    info "Applying network hardening"

    setup_nftables
    setup_geoblock

    # remove firewalld
    doas systemctl disable --now firewalld.service
    remove_packages firewalld*

    # Load base firewall and GeoBlock rules.
    doas systemctl enable --now nftables.service

    setup_hagezi_blocklist
    setup_unbound
    configure_network_dns

    success "Network hardening complete"
}

