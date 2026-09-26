#!/usr/bin/env bash

set -euo pipefail

source "$CONFIG_DIR/packages/$DISTRO/desktop.conf"

install_desktop_packages() {
    info "Installing desktop packages"

    install_packages "${DESKTOP_PACKAGES[@]}"

    mkdir -p "$HOME/.config"

    cp -r "$CONFIG_DIR/desktop/foot" "$HOME/.config/"

    success "Desktop packages configured"
}

install_font() {
    local font_dir="$HOME/.local/share/fonts"
    local tmp_dir archive url digest
    
    install_packages unzip

    mkdir -p "$font_dir"

    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' RETURN

    read -r url digest < <(
        curl -fsSL --retry 3 \
            https://api.github.com/repos/googlefonts/googlesans-code/releases/latest |
            jq -er '
                .assets[]
                | select(.name | test("^GoogleSansCode-v[0-9.]+\\.zip$"))
                | [.browser_download_url, .digest]
                | @tsv
            '
    )

    archive="$tmp_dir/archive.zip"

    curl -fsSL --retry 3 -o "$archive" "$url"

    printf '%s  %s\n' "${digest#sha256:}" "$archive" |
        sha256sum -c -

    unzip -jo "$archive" '*.ttf' -d "$tmp_dir" >/dev/null

    install -Dm644 "$tmp_dir/GoogleSansCode[MONO,wght].ttf" \
        "$font_dir/google_sans_code.ttf"

    chmod 400 "$font_dir/google_sans_code.ttf"

    restorecon -Rv -F "$font_dir"

    fc-cache -f "$font_dir"
}

setup_desktop() {
    install_desktop_packages
    install_font
    success "Desktop setup completed"
}
