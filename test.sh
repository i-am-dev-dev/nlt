# ==============================================================================
# TESTING NOTES
# ==============================================================================
# Run all tests from the directory containing this script.
# Make sure it is executable first:
#   chmod +x display_set.sh
#
# Expected outcomes are noted inline for each test.
# A PASS means the script behaves exactly as described.
# A FAIL means something is broken and needs investigation.
#
# ------------------------------------------------------------------------------
# 1. ARGUMENT COUNT VALIDATION
# ------------------------------------------------------------------------------
#
# Too few arguments (only 1):
#   ./display_set.sh 0.8
#   EXPECT: prints usage string, exits — no xrandr or redshift calls made
#
# Too many arguments (4 args):
#   ./display_set.sh 0.8 3000 4000 5000
#   EXPECT: prints usage string, exits — no xrandr or redshift calls made
#
# No arguments at all:
#   ./display_set.sh
#   EXPECT: prints usage string, exits cleanly
#
# ------------------------------------------------------------------------------
# 2. BRIGHTNESS VALIDATION
# ------------------------------------------------------------------------------
#
# Valid brightness — lower boundary:
#   ./display_set.sh 0.4 3000
#   EXPECT: accepted, brightness applied to all displays
#
# Valid brightness — upper boundary:
#   ./display_set.sh 1.0 3000
#   EXPECT: accepted, brightness applied to all displays
#
# Valid brightness — midpoint:
#   ./display_set.sh 0.7 3000
#   EXPECT: accepted, brightness applied to all displays
#
# Invalid brightness — too low:
#   ./display_set.sh 0.1 3000
#   EXPECT: error message, redshift -x reset called, exit
#
# Invalid brightness — too high:
#   ./display_set.sh 1.5 3000
#   EXPECT: error message, redshift -x reset called, exit
#
# Invalid brightness — zero:
#   ./display_set.sh 0 3000
#   EXPECT: error message, redshift -x reset called, exit
#
# Invalid brightness — negative:
#   ./display_set.sh -0.5 3000
#   EXPECT: error message, redshift -x reset called, exit
#
# Invalid brightness — non-numeric string:
#   ./display_set.sh abc 3000
#   EXPECT: error message, redshift -x reset called, exit
#
# Invalid brightness — empty string (quoted):
#   ./display_set.sh "" 3000
#   EXPECT: error message, redshift -x reset called, exit
#
# ------------------------------------------------------------------------------
# 3. COLOR TEMPERATURE (TEMP1) VALIDATION
# ------------------------------------------------------------------------------
#
# Valid temp — lower boundary:
#   ./display_set.sh 0.8 2500
#   EXPECT: accepted, redshift -O 2500 called
#
# Valid temp — upper boundary:
#   ./display_set.sh 0.8 4500
#   EXPECT: accepted, redshift -O 4500 called
#
# Valid temp — midpoint:
#   ./display_set.sh 0.8 3500
#   EXPECT: accepted, redshift -O 3500 called
#
# Invalid temp — below minimum:
#   ./display_set.sh 0.8 2499
#   EXPECT: error message, redshift -x reset called, exit
#
# Invalid temp — above maximum:
#   ./display_set.sh 0.8 4501
#   EXPECT: error message, redshift -x reset called, exit
#
# Invalid temp — zero:
#   ./display_set.sh 0.8 0
#   EXPECT: error message, redshift -x reset called, exit
#
# Invalid temp — float value:
#   ./display_set.sh 0.8 3000.5
#   EXPECT: error message — is_int_in_range rejects non-integers, redshift -x called, exit
#
# Invalid temp — negative value:
#   ./display_set.sh 0.8 -3000
#   EXPECT: error message, redshift -x reset called, exit
#
# Invalid temp — non-numeric string:
#   ./display_set.sh 0.8 warm
#   EXPECT: error message, redshift -x reset called, exit
#
# ------------------------------------------------------------------------------
# 4. OPTIONAL SECOND TEMPERATURE (TEMP2) VALIDATION
# ------------------------------------------------------------------------------
#
# Valid temp2 — typical use:
#   ./display_set.sh 0.8 3000 4000
#   EXPECT: redshift -O 3000 called first, then redshift -O 4000
#
# Valid temp2 — same as temp1:
#   ./display_set.sh 0.8 3000 3000
#   EXPECT: redshift called twice with 3000 — no error, this is allowed
#
# Valid temp2 — boundary values:
#   ./display_set.sh 0.8 2500 4500
#   EXPECT: both temperatures accepted and applied in order
#
# Invalid temp2 — out of range:
#   ./display_set.sh 0.8 3000 9999
#   EXPECT: temp1 applied successfully, then error on temp2, redshift -x called, exit
#
# Invalid temp2 — non-numeric:
#   ./display_set.sh 0.8 3000 hot
#   EXPECT: temp1 applied successfully, then error on temp2, redshift -x called, exit
#
# ------------------------------------------------------------------------------
# 5. DISPLAY DETECTION
# ------------------------------------------------------------------------------
#
# Single display connected (typical laptop):
#   ./display_set.sh 0.8 3000
#   EXPECT: one display name printed (e.g. eDP-1), brightness set on that display only
#
# Multiple displays connected (laptop + external monitor):
#   ./display_set.sh 0.8 3000
#   EXPECT: all connected display names printed, brightness applied to each in sequence
#           any display that fails gets a warning but does not abort the rest
#
# Simulate no displays found (manual test — requires patching get_connected_displays):
#   Temporarily replace get_connected_displays body with: return
#   ./display_set.sh 0.8 3000
#   EXPECT: error_exit fires with "No connected displays found via xrandr"
#
# Display name with dash and number (common real-world names):
#   Covers: eDP-1, HDMI-1, HDMI-2, DP-1, DP-2, VGA-1
#   EXPECT: xrandr --output <name> --brightness called correctly for each
#
# ------------------------------------------------------------------------------
# 6. DEPENDENCY CHECKING
# ------------------------------------------------------------------------------
#
# Both dependencies present:
#   which redshift && which xrandr   (verify they exist first)
#   ./display_set.sh 0.8 3000
#   EXPECT: no dependency prompt shown, script proceeds normally
#
# Simulate missing redshift (rename it temporarily):
#   sudo mv $(which redshift) $(which redshift).bak
#   ./display_set.sh 0.8 3000
#   EXPECT: dependency check catches it, prints install command for current distro,
#           prompts user to auto-install or exit
#   sudo mv $(which redshift).bak $(which redshift)   (restore after test)
#
# Simulate missing xrandr:
#   sudo mv $(which xrandr) $(which xrandr).bak
#   ./display_set.sh 0.8 3000
#   EXPECT: dependency check catches it, prints correct install suggestion,
#           prompts user — same flow as above
#   sudo mv $(which xrandr).bak $(which xrandr)   (restore after test)
#
# Simulate both missing:
#   sudo mv $(which redshift) $(which redshift).bak
#   sudo mv $(which xrandr) $(which xrandr).bak
#   ./display_set.sh 0.8 3000
#   EXPECT: both listed together in the missing block, single prompt for both
#   (restore both after test)
#
# Auto-install declined (type N at prompt):
#   EXPECT: prints "Please install manually" message and exits cleanly
#
# Auto-install accepted on unknown package manager:
#   Temporarily clear PATH of known package managers to force "unknown"
#   EXPECT: prints error that package manager could not be detected, exits
#
# ------------------------------------------------------------------------------
# 7. PACKAGE MANAGER DETECTION
# ------------------------------------------------------------------------------
#
# Verify correct install command is suggested per distro:
#
#   apt-based (Ubuntu, Debian, Mint):
#     EXPECT: "sudo apt install -y redshift" / "sudo apt install -y x11-xserver-utils"
#
#   dnf-based (Fedora, RHEL, CentOS Stream):
#     EXPECT: "sudo dnf install -y redshift" / "sudo dnf install -y xrandr"
#
#   pacman-based (Arch, Manjaro, EndeavourOS):
#     EXPECT: "sudo pacman -S --noconfirm redshift" / "sudo pacman -S --noconfirm xorg-xrandr"
#
#   zypper-based (openSUSE):
#     EXPECT: "sudo zypper install -y redshift" / "sudo zypper install -y xrandr"
#
#   apk-based (Alpine):
#     EXPECT: "sudo apk add redshift" / "sudo apk add xrandr"
#
#   No known package manager:
#     EXPECT: fallback message — "install manually — package manager not detected"
#
# ------------------------------------------------------------------------------
# 8. EDGE CASES & STRESS
# ------------------------------------------------------------------------------
#
# Brightness as integer without decimal:
#   ./display_set.sh 1 3000
#   EXPECT: awk float check should still accept this as 1.0 — verify PASS
#
# Very precise float:
#   ./display_set.sh 0.400001 3000
#   EXPECT: accepted (just above minimum)
#
# Whitespace in arguments:
#   ./display_set.sh " 0.8" 3000
#   EXPECT: likely fails float validation — document whether this is desired behaviour
#
# Calling with -- separator:
#   ./display_set.sh -- 0.8 3000
#   EXPECT: arg count check receives 3 args, -- becomes $1 (brightness), validate behaviour
#
# Script run as root:
#   sudo ./display_set.sh 0.8 3000
#   EXPECT: xrandr may fail without a valid DISPLAY env var when run as root
#           if DISPLAY is unset, document the failure mode clearly
#
# DISPLAY env var unset (headless/SSH session):
#   DISPLAY= ./display_set.sh 0.8 3000
#   EXPECT: xrandr fails, error_exit fires — verify redshift -x is also attempted
#           (it will likely also fail — both failures should be surfaced clearly)
#
# ==============================================================================
