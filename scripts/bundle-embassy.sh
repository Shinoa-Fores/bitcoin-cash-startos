#!/bin/sh
set -e

echo "Bundling TypeScript files with Deno..."
echo "Deno version: $(deno --version 2>/dev/null || echo 'Deno not found')"
echo "Current directory: $(pwd)"
echo "Checking embassy.ts file..."
if [ ! -f scripts/embassy.ts ]; then
  echo "ERROR: scripts/embassy.ts not found"
  exit 1
fi
echo "Attempting to bundle with deno (up to 5 attempts)..."
i=1
while [ $i -le 5 ]; do
  echo "Attempt $i of 5..."
  if deno bundle scripts/embassy.ts scripts/embassy.js; then
    echo "Successfully created scripts/embassy.js"
    break
  else
    echo "Attempt $i failed"
    if [ $i -lt 5 ]; then
      echo "Retrying in 10 seconds..."
      sleep 10
    else
      echo "All attempts failed. Checking for network issues..."
      echo "Contents of scripts directory:"
      ls -la scripts/
      echo "Contents of scripts/services directory:"
      ls -la scripts/services/ 2>/dev/null || echo "services directory not found"
      exit 1
    fi
  fi
  i=$((i+1))
done
if [ ! -f scripts/embassy.js ]; then
  echo "ERROR: Failed to create scripts/embassy.js after all attempts"
  exit 1
fi
