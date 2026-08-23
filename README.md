# Linux Network Diagnostics

![Bash](https://img.shields.io/badge/Bash-Scripting-4EAA25)
![Linux](https://img.shields.io/badge/Linux-Ubuntu-E95420)
![iproute2](https://img.shields.io/badge/iproute2-Networking-0078D4)
![Version](https://img.shields.io/badge/Version-0.1-blue)
![Status](https://img.shields.io/badge/Status-In%20Development-orange)

A lightweight Bash-based command-line tool for inspecting basic network information on Linux systems.

This project is being developed as part of my Platform Engineering learning roadmap, specifically within the Networking section. The goal is to practice Linux networking, Bash scripting, command-line tools, text processing, and modular scripting.

## Current Status

**Version:** v0.1

The project currently provides an interactive terminal menu for accessing network diagnostics.

### Currently Implemented

- Interactive command-line menu
- Network interface information
- Host IP information
- Network interface detection
- Interface counting
- IPv4 address information
- IPv6 address information
- Basic RX/TX network statistics
- Modular Bash scripting structure

### Planned

The project will gradually be expanded with additional network diagnostics, including:

- Routing information
- Connectivity diagnostics
- DNS diagnostics
- Network service diagnostics
- Additional network statistics and analysis

---

## Requirements

The project can run on Linux or Linux Environments with WSL 2.

* WSL 2 (**not required** for native Linux Systems) 
* Linux (Ubuntu)
* Bash

> [!NOTE]
> For the project, I installed `iproute2` for `ip` commands.

### Installation

Clone the repository:
```
git clone https://github.com/Nur-Howell/lnd.git
```
Enter the project directory:
```
cd lnd
```
Ensure `netdiag` and `main.sh` has execution permissions:
```
chmod +x bin/netdiag
chmod +x src/main.sh
```

### Running the program

In the project root directory:
```
./bin/netdiag
```
This will launch the program and the interactive terminal menu should appear:
```
======= Menu =======
1. Interface Info
2. Exit

Select an option:
```



---

## Project Structure

```text
.
├── README.md
├── bin
│   └── netdiag
├── docs
│   ├── 2026-08-19.md
│   └── 2026_08_20.md
└── src
    ├── main.sh
    ├── network
    │   └── interfaces.sh
    └── ui
        └── menu.sh

