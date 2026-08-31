#!/bin/bash

# Ensure the script is run with root privileges to access process memory
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root (e.g., sudo $0)."
  exit 1
fi

# Require a search argument so personal data isn't hardcoded for GitHub
if [ -z "$1" ]; then
  echo "Usage: $0 <search_string>"
  echo "Example: $0 juI628UR"
  echo "Example: $0 sip32.binotel.com"
  exit 1
fi

SEARCH="$1"
PIDS=$(pgrep -i zoiper)

if [ -z "$PIDS" ]; then
  echo "Error: No Zoiper processes found running."
  exit 1
fi

# Create a secure temporary directory to hold the large memory files
TMP_DIR=$(mktemp -d)
echo "[+] Created temporary directory: $TMP_DIR"

# Set a trap to ensure memory dumps are automatically and securely deleted upon exit or interrupt
trap 'echo "[+] Cleaning up memory dumps from disk..."; rm -rf "$TMP_DIR"' EXIT

echo "[+] Found Zoiper PIDs. Generating memory dumps..."
for pid in $PIDS; do
  echo " -> Dumping memory for PID $pid"
  gcore -o "$TMP_DIR/zoiper_mem" "$pid" > /dev/null 2>&1
done

echo "[+] Searching extracted memory for '$SEARCH'..."
echo "---------------------------------------------------"
strings "$TMP_DIR"/zoiper_mem* | grep -C 15 "$SEARCH"
echo "---------------------------------------------------"
echo "[+] Process complete."
