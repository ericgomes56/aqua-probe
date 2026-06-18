<img src="/misc/aqua_probe_1x1.png" width="300" height="300">


# Aqua Probe: The Aqua Security Runtime Input Validator Tool

## Overview
Aqua Probe is an interactive command-line tool designed to explore runtime security features provided by Aqua Security within Kubernetes environments. It allows users to experience Real-Time Malware Protection, Drift Prevention, and other security controls offered by Aqua.

<video src="/misc/aqua-probe-tool-demo.mov" height="500" controls></video>

## Features
1. Deploy a test container within a Kubernetes cluster
2. Test Real-time Malware Protection with delete action
3. Test Drift Prevention 
4. Test Block Cryptocurrency Mining
5. Test Block Fileless Exec 
6. Test Block Reverse Shell
7. Test Executables Blocked (ps)
8. Test Block Container Exec

## Usage
1. Ensure you have `kubectl` configured to connect to your Kubernetes cluster.
2. Run the script by executing `./aqua-probe.sh`.
3. Follow the on-screen prompts to deploy the test container and perform security tests.

## Requirements
- Bash shell
- `kubectl` configured to connect to a Kubernetes cluster
- Aqua Enforcer daemonset deployed in the Kubernetes cluster
- Internet access to a Docker registry or the ability to push the Aqua Probe test image (ericgomes56/aqua-probe:1.0) to a local registry
- Permissions to deploy container in the Kubernetes cluster (ericgomes56/aqua-probe:1.0)

## Installation
1. Clone this repository to your local machine
2. Ensure you have the necessary permissions to execute the script (`chmod +x aqua-probe.sh`)

## Usage Example
```bash
# Default mode - utilizes ericgomes56/aqua-probe:1.0 image
./aqua-probe.sh

# Advanced mode
./aqua-probe.sh --no-instructions --image <image_name>
./aqua-probe.sh -n -i <image_name>
```

<img src="/misc/aqua-probe-advanced-commands.png" height="300">

## Additional commands
Set the custom daemonset name where the Aqua Enforcer is deployed (default: aqua-agent,kube-enforcer-ds)
```bash
./aqua-probe.sh --daemonset <value>, -d <value>
```
Show help menu which contains the list of commands 
```bash
./aqua-probe.sh --help, -h
```
Reference local registry image (default: ericgomes56/aqua-probe:1.0)
```bash
./aqua-probe.sh --image <image_name>, -i <image_name>
```
Skip test prerequisites instructions
```bash
./aqua-probe.sh --no-instructions, -n
```
Show the current Aqua Probe build version
```bash
./aqua-probe.sh --version, -v
```

## Aqua Probe Image
Container image examples use `ericgomes56/aqua-probe:1.0`.
