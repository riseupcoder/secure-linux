# secure-linux

**Build a hardened Linux system you understand and control.**

<div align="center">

[![Fedora](https://img.shields.io/badge/Primary%20Target-Fedora%20Minimal-51A2DA?logo=fedora&logoColor=white)](https://fedoraproject.org/)
[![Bash](https://img.shields.io/badge/Bash-5.x-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![SELinux](https://img.shields.io/badge/SELinux-Hardening-red.svg)](https://selinuxproject.github.io/)
[![OpenDoas](https://img.shields.io/badge/Privilege%20Escalation-OpenDoas-blue.svg)](https://github.com/Duncaen/OpenDoas)

</div> 

## Description

**secure-linux** is a hands-on approach to building a hardened Linux system from the ground up.

The project takes a layered approach to security: remove what is unnecessary, reduce what is privileged, confine what can be confined, and harden the components that remain. It covers everything from replacing sudo with OpenDoas and reducing the system footprint to kernel hardening, SUID/SGID reduction, hardened memory allocation, systemd service sandboxing, and SELinux confinement.

The idea behind secure-linux is simple: **security should be something you understand, control, and build for yourself**. Instead of relying entirely on distribution defaults or a security-focused operating system, this project gives you the building blocks to understand what is happening on your system and make those decisions yourself.

**The scripts are not meant to be something you simply run and forget. Take the time to understand what each script changes and why it is there**. The goal is not just to end up with a hardened machine, but to learn enough about Linux security to eventually build and adapt one yourself, based on your own needs and threat model.

With the growing number of vulnerabilities and AI-assisted attacks, knowing how to secure the systems we rely on is becoming increasingly important. **secure-linux is my attempt to learn that process, put it into practice, and share what I learn along the way**.


## Features

- **Privilege Separation** — Removes `sudo` and replaces it with OpenDoas as the primary privilege-escalation mechanism.
- **System Minimization** — Further debloats a minimal Linux installation by removing unnecessary packages and components.
- **Account Hardening** — Disables direct root login, restricts `su`, and increases password hashing rounds to `65536`.
- **Kernel Hardening** — Hardens kernel configuration and disables unnecessary kernel modules to reduce the system's kernel attack surface.
- **Hardened Memory Allocation** — Replaces the default memory allocator with GrapheneOS hardened_malloc and enables its default variant.
- **Service Sandboxing** — Applies systemd sandboxing restrictions to NetworkManager.
- **SUID/SGID Reduction** — Removes unnecessary SUID/SGID privileges from host binaries while retaining `doas` for controlled privilege transitions.
- **Unified Kernel Image**: Transitions the system to a UKI-based boot architecture with customized kernel installation and boot configuration.
- **Minimal Userspace**: Installs a lean set of essential packages for graphics, audio, and container workloads.
- **SELinux Hardening** — Installs custom SELinux policies for user namespace restrictions, legacy socket restrictions, and hardens selected SELinux booleans.
- **SELinux User Confinement** — Maps the everyday user to user_u and creates a separate administrative account for privileged tasks.
- **Custom Hardened Kernel** — Builds a kernel tailored to your system with the Anthraxx linux-hardened patch set applied.

### Prerequisites

- Intermediate Linux knowledge
- Basic SELinux knowledge

You should be comfortable working with Linux permissions, users and groups, package management, kernel configuration, kernel modules,  and Basic SELinux concepts.

## Requirements

- Fedora Minimal System
- Internet connection

## Getting Started

Clone the repository:

```bash
git clone https://github.com/riseupcoder/secure-linux
cd secure-linux
./install.sh
```

## Questions & Discussions
Have questions about a script, want to understand a security decision, or have an idea for the project? Open a Discussion.

## License

This project is licensed under the MIT License.
