#!/bin/bash

echo "Starting the script..."

# Check if file argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <env-file>"
    exit 1
fi

echo "Argument provided: $1"

# Get the file from the first argument
envFile="$1"

# Check if file exists
if [ ! -f "$envFile" ]; then
    echo "Error: File '$envFile' not found."
    exit 1
fi

echo "Reading environment file: $envFile"

# Read contents of the environment file
envContents=$(cat "$envFile")

# Extract environment variable names and references from contents
echo "Extracting environment variable names and references from file content..."
names=()
references=()
for line in $envContents; do
    if [[ $line =~ ^[a-zA-Z_][a-zA-Z0-9_]*=\"?\$\{[a-zA-Z_][a-zA-Z0-9_]*\}\"? ]]; then
        name=$(echo $line | grep -oP '^[a-zA-Z_][a-zA-Z0-9_]*(?=\=)')
        reference=$(echo $line | grep -oP '(?<=\$\{)[a-zA-Z_][a-zA-Z0-9_]*(?=\})')
        names+=($name)
        references+=($reference)
        echo "Found variable: $name with reference: ${reference}"
    fi
done

# Get all environment variables
echo "Fetching all environment variables..."
envLines=$(printenv | cut -d '=' -f1)

# Check for missing variables
missing=()
ignoredReferences=("APP_KEY" "APP_NAME")

for reference in ${references[@]}; do
    echo "Checking variable: $reference"

    # Check if the reference is in ignoredReferences
    ignore=false
    for ignoredReference in ${ignoredReferences[@]}; do
        if [ "$reference" == "$ignoredReference" ]; then
            ignore=true
            echo "Ignoring variable: $reference"
            break
        fi
    done

    if [ "$ignore" == true ]; then
        continue
    fi

    found=false
    for env in $envLines; do
        if [ "$env" == "$reference" ]; then
            found=true
            echo "Variable found in environment: $reference"
            break
        fi
    done

    # Add to missing only if it's in the references array
    if [ "$found" == false ]; then
      if [[ ! " ${names[*]} " =~ " ${reference} " ]]; then
        if [[ ! " ${missing[*]} " =~ " ${reference} " ]]; then
            missing+=($reference)
            echo "Missing variable: $reference"
        fi
      fi
    fi
done

# Throw error if missing variables
if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing variables: ${missing[*]}"
    exit 1
fi

echo "Script execution completed successfully."
