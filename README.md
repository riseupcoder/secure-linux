# secure-linux

**Build a hardened Linux system you understand and control.**

<div align="center">

[![Fedora](https://img.shields.io/badge/Primary%20Target-Fedora%20Minimal-51A2DA?logo=fedora&logoColor=white)](https://fedoraproject.org/)
[![Bash](https://img.shields.io/badge/Bash-5.x-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![SELinux](https://img.shields.io/badge/SELinux-Hardening-red.svg)](https://selinuxproject.github.io/)
[![OpenDoas](https://img.shields.io/badge/Privilege%20Escalation-OpenDoas-blue.svg)](https://github.com/Duncaen/OpenDoas)

</div>

## Description

**secure-linux** is a hands-on project for building and hardening a Linux system from the ground up, with security and system control at its core.

It follows a layered security approach: minimize the system footprint, eliminate unnecessary privileges, restrict network exposure, harden system services, and enforce mandatory access controls.

Through modular Bash scripts and carefully maintained configuration files, the project brings together multiple layers of Linux security, including account and kernel hardening, SELinux policy enforcement, systemd service sandboxing, host firewalling, DNS filtering, geographic IP blocking, and hardened memory allocation.

Rather than relying entirely on distribution defaults or preconfigured security solutions, **secure-linux gives you the building blocks to understand, customize, and control your system's security posture.**

**This project is not intended to be something you simply run and forget.** Every script and configuration exists for a reason. Take the time to understand what it changes, why it matters, and how it affects your system.

The goal extends beyond building a hardened machine: **it's about developing the knowledge and practical experience to secure, maintain, and adapt a Linux system according to your own requirements and threat model.**

**secure-linux is my journey into Linux security, turning what I learn into practical implementations and sharing that knowledge along the way.**

## Features

### System Hardening

- **Privilege Management** — Replaces `sudo` with OpenDoas, providing a minimal and streamlined mechanism for controlled administrative privilege escalation.
- **System Minimization** — A lean Fedora installation with unnecessary packages and components stripped away.
- **Account Security** — Restricted root access, controlled `su` privileges, secure default file permissions, and stronger password hashing.
- **Kernel Hardening** — Hardened kernel parameters, restricted kernel modules, and protected sensitive system directories.
- **Memory Corruption Protection** — GrapheneOS hardened_malloc with its default security configuration for stronger heap memory protection.
- **SUID/SGID Privilege Reduction** — Unnecessary elevated privileges removed while preserving essential exceptions and required capabilities.
- **Unified Kernel Image**: Transitions the system to a UKI-based boot architecture with customized kernel installation and boot configuration.
- **Custom Hardened Kernel** — Builds a kernel tailored to your system with the Anthraxx linux-hardened patch set applied.

### Network Security

- **Default-Deny Firewall** — Enforces strict inbound and forwarding traffic policies through stateful nftables filtering.
- **Country-Level IP Blocking** — Blocks entire countries at the network level using IPv4 and IPv6 address ranges.
- **Advanced DNS Threat Protection** — Combines HaGeZi Ultimate and Threat Intelligence Feeds (TIF) to block ads, trackers, telemetry, phishing, malware, scams, fraudulent domains, cryptojacking, and other internet threats.
- **DNS Privacy & Control** — Centralizes DNS resolution through Unbound, providing control over upstream DNS forwarding and local name resolution.
- **Network Configuration Hardening** — Restricts unwanted DNS configuration changes and strengthens NetworkManager service security.
- **Automatic Threat Intelligence Updates** — Automatically refreshes country-level IP blocklists and DNS threat feeds daily, keeping network defenses current against changing threats, malicious domains, and emerging security risks.

### SELinux Hardening

- **SELinux User Namespace Isolation** — Prevents untrusted processes from exploiting user namespaces to gain elevated privileges.
- **Socket Attack Surface Reduction** — Restricts unnecessary and potentially risky socket families, including packet radio, IPsec, ALG, and other obscure socket interfaces.
- **Custom SELinux Confinement** — Extends mandatory access control with dedicated policies for Wayland, dwl, and seatd.
- **SELinux Policy Hardening** — Enforces restrictive SELinux boolean settings to limit unnecessary system privileges.
- **Privileged User Isolation** — Keeps everyday user activity confined while reserving administrative privileges for a separate account.

### Service Hardening

- **Systemd Sandboxing** — Applies additional restrictions to selected system services to reduce their privileges and available attack surface.

## Prerequisites

- Intermediate Linux knowledge.
- Basic Bash scripting knowledge.
- Familiarity with Linux permissions, users and groups, systemd, and package management.
- Basic understanding of SELinux and Linux networking.

## Requirements

- Fedora Minimal installation.
- Internet connection.

## Getting Started

Clone the repository:

```bash
git clone https://github.com/riseupcoder/secure-linux.git
cd secure-linux
./install.sh
```

## Questions & Discussions
Have questions about a script, want to understand a security decision, or have an idea for the project? Open a Discussion. 

## License

This project is licensed under the MIT License.
