#!/usr/bin/env bash

# ---- CONFIG ----
MIN_BRIGHT=0.4
MAX_BRIGHT=1.0
MIN_TEMP=2500
MAX_TEMP=4500

# ---- DEPENDENCIES ----
REQUIRED_CMDS=("redshift" "xrandr")

detect_pkg_manager() {
    for pm in apt dnf pacman zypper apk; do
        if command -v "$pm" &>/dev/null; then
            echo "$pm"
            return
        fi
    done
    echo "unknown"
}

get_install_cmd() {
    local pkg=$1
    case $(detect_pkg_manager) in
        apt)     echo "sudo apt install -y $pkg" ;;
        dnf)     echo "sudo dnf install -y $pkg" ;;
        pacman)  echo "sudo pacman -S --noconfirm $pkg" ;;
        zypper)  echo "sudo zypper install -y $pkg" ;;
        apk)     echo "sudo apk add $pkg" ;;
        *)       echo "(install manually — package manager not detected)" ;;
    esac
}

check_dependencies() {
    local missing=()

    for cmd in "${REQUIRED_CMDS[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        return 0
    fi

    echo "============================================"
    echo "  Missing dependencies detected:"
    echo "============================================"
    for cmd in "${missing[@]}"; do
        echo ""
        echo "  ✗ '$cmd' not found"
        echo "    Install with: $(get_install_cmd "$cmd")"
    done
    echo ""

    read -rp "Attempt to auto-install missing dependencies now? [y/N]: " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        local pm
        pm=$(detect_pkg_manager)
        if [[ "$pm" == "unknown" ]]; then
            echo "Error: Could not detect a supported package manager. Please install manually."
            exit 1
        fi
        for cmd in "${missing[@]}"; do
            echo "Installing '$cmd'..."
            $(get_install_cmd "$cmd") || {
                echo "Error: Failed to install '$cmd'. Please install it manually."
                exit 1
            }
        done
        echo "All dependencies installed successfully."
        echo "============================================"
    else
        echo "Please install the missing dependencies and re-run the script."
        exit 1
    fi
}

# ---- DISPLAY DETECTION ----
get_connected_displays() {
    xrandr | awk '/ connected/ { print $1 }'
}

apply_brightness_to_all() {
    local brightness=$1
    local displays
    mapfile -t displays < <(get_connected_displays)

    if [[ ${#displays[@]} -eq 0 ]]; then
        error_exit "No connected displays found via xrandr"
    fi

    echo "Detected display(s): ${displays[*]}"

    local failed=()
    for display in "${displays[@]}"; do
        echo "  → Setting brightness $brightness on '$display'"
        if ! xrandr --output "$display" --brightness "$brightness"; then
            echo "  ✗ Failed on '$display' — skipping"
            failed+=("$display")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        echo "Warning: brightness could not be set on: ${failed[*]}"
    fi
}

# ---- FUNCTIONS ----
error_exit() {
    echo "Error: $1"
    echo "Resetting display..."
    redshift -x
    exit 1
}

is_float_in_range() {
    local val=$1
    awk -v v="$val" -v min="$MIN_BRIGHT" -v max="$MAX_BRIGHT" \
        'BEGIN { exit !(v >= min && v <= max) }'
}

is_int_in_range() {
    local val=$1
    [[ "$val" =~ ^[0-9]+$ ]] || return 1
    (( val >= MIN_TEMP && val <= MAX_TEMP ))
}

# ---- RUN DEPENDENCY CHECK ----
check_dependencies

# ---- INPUT CHECK ----
if (( $# < 2 || $# > 3 )); then
    echo "Usage: $0 <brightness> <temp1> [temp2]"
    exit 1
fi

BRIGHTNESS=$1
TEMP1=$2
TEMP2=$3

# ---- VALIDATE BRIGHTNESS ----
if ! is_float_in_range "$BRIGHTNESS"; then
    error_exit "Brightness must be between $MIN_BRIGHT and $MAX_BRIGHT"
fi

# ---- APPLY BRIGHTNESS TO ALL DISPLAYS ----
apply_brightness_to_all "$BRIGHTNESS"

# ---- VALIDATE TEMP1 ----
if ! is_int_in_range "$TEMP1"; then
    error_exit "Color temp must be between $MIN_TEMP and $MAX_TEMP"
fi

echo "Applying redshift $TEMP1"
redshift -O "$TEMP1" || error_exit "redshift failed"

# ---- OPTIONAL TEMP2 ----
if [[ -n "$TEMP2" ]]; then
    if ! is_int_in_range "$TEMP2"; then
        error_exit "Second temp must be between $MIN_TEMP and $MAX_TEMP"
    fi
    echo "Applying second redshift $TEMP2"
    redshift -O "$TEMP2" || error_exit "second redshift failed"
fi

echo "Done."

