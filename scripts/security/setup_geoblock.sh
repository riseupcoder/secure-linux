#!/usr/bin/env bash

readonly COUNTRIES=(ru cn kp pk ir iq tr vn ng)
readonly BASE_URL="https://raw.githubusercontent.com/ipverse/geo-ip-blocks/master/country"
readonly NFT_DIR="/etc/nftables"
readonly GEO_DIR="$NFT_DIR/geo"
readonly NFT_FILE="$NFT_DIR/geoblock.nft"
readonly SERVICE_FILE="/etc/systemd/system/geoblock.service"
readonly NFT_BIN="$(command -v nft)"

download_country_lists() {
    info "Downloading GeoBlock country IP lists"

    for country in "${COUNTRIES[@]}"; do
        for family in ipv4 ipv6; do
            local file="$TEMP_DIR/$country.$family"
            local url="$BASE_URL/$country/$country-$family.txt"
            local http_code

            http_code=$(curl -sSL \
                --retry 3 \
                --retry-delay 2 \
                --connect-timeout 15 \
                --max-time 120 \
                -o "$file" \
                -w '%{http_code}' \
                "$url")

            if [[ "$http_code" == "404" && "$family" == "ipv6" ]]; then
                : > "$file"
                continue
            fi

            [[ "$http_code" == "200" && -s "$file" ]] || {
                echo "ERROR: Invalid download: $country ($family), HTTP $http_code" >&2
                return 1
            }
        done

        printf '  %-3s IPv4: %-7s IPv6: %s\n' "$country" \
            "$(grep -vc '^#' "$TEMP_DIR/$country.ipv4")" \
            "$(grep -vc '^#' "$TEMP_DIR/$country.ipv6")"
    done
}

generate_ruleset() {
    info "Generating GeoBlock nftables ruleset"

    doas install -d -m 755 "$NFT_DIR"

    {
        cat <<'NFT'
destroy table inet geoblock

table inet geoblock {
    set block4 {
        type ipv4_addr
        flags interval
        auto-merge
        elements = {
NFT

        awk '!/^#/ && NF {
                 printf "%s%s", sep, $0
                 sep = ",\n            "
             }
             END { print "" }' "$TEMP_DIR"/*.ipv4

        cat <<'NFT'
        }
    }

    set block6 {
        type ipv6_addr
        flags interval
        auto-merge
        elements = {
NFT

        awk '!/^#/ && NF {
                 printf "%s%s", sep, $0
                 sep = ",\n            "
             }
             END { print "" }' "$TEMP_DIR"/*.ipv6

        cat <<'NFT'
        }
    }

    chain input {
        type filter hook input priority -1; policy accept;
        ip saddr @block4 drop
        ip6 saddr @block6 drop
    }

    chain output {
        type filter hook output priority -1; policy accept;
        ip daddr @block4 drop
        ip6 daddr @block6 drop
    }

    chain forward {
        type filter hook forward priority -1; policy accept;
        ip saddr @block4 drop
        ip daddr @block4 drop
        ip6 saddr @block6 drop
        ip6 daddr @block6 drop
    }
}
NFT
    } | doas tee "$NFT_FILE" >/dev/null

    local total4 total6

    total4=$(grep -hv '^#' "$TEMP_DIR"/*.ipv4 | awk 'NF { n++ } END { print n+0 }')
    total6=$(grep -hv '^#' "$TEMP_DIR"/*.ipv6 | awk 'NF { n++ } END { print n+0 }')

    info "IPv4 CIDRs: $total4"
    info "IPv6 CIDRs: $total6"
    info "Total CIDRs: $((total4 + total6))"
}

validate_and_install_ruleset() {
    info "Validating GeoBlock ruleset"

    doas restorecon -v "$NFT_FILE"
    doas "$NFT_BIN" -c -f "$NFT_FILE"

    doas install -d -m 755 "$GEO_DIR"
    doas install -m 644 "$TEMP_DIR"/*.ipv4 "$GEO_DIR/"
    doas install -m 644 "$TEMP_DIR"/*.ipv6 "$GEO_DIR/"

    success "GeoBlock ruleset validated and installed"
}

install_geoblock_service() {
    info "Installing GeoBlock systemd service"

    doas tee "$SERVICE_FILE" >/dev/null <<UNIT
[Unit]
Description=GeoBlock country IPv4 and IPv6 filtering
After=firewalld.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$NFT_BIN -f $NFT_FILE
ExecStop=-$NFT_BIN delete table inet geoblock

[Install]
WantedBy=multi-user.target
UNIT

    doas systemctl daemon-reload
    doas systemctl enable geoblock.service
    doas systemctl restart geoblock.service

    doas "$NFT_BIN" list table inet geoblock >/dev/null

    success "GeoBlock service enabled"
}

setup_geoblock() {
    info "Setting up GeoBlock"

    create_temp_directory

    download_country_lists
    generate_ruleset
    validate_and_install_ruleset
    install_geoblock_service

    remove_temp_directory

    success "GeoBlock setup completed"
}

