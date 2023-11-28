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

# Extract environment variable names from contents
echo "Extracting environment variable names from file content..."
names=()
for line in $envContents; do
    if [[ $line =~ \$\{[a-zA-Z_][a-zA-Z0-9_]*\} ]]; then
        name=$(echo $line | grep -oP '\$\{\K[a-zA-Z_][a-zA-Z0-9_]*(?=\})')
        names+=($name)
        echo "Found variable: $name"
    fi
done

# Get all environment variables
echo "Fetching all environment variables..."
envLines=$(printenv | cut -d '=' -f1)

# Check for missing variables
missing=()
ignoredNames=("APP_KEY" "APP_NAME")

for name in ${names[@]}; do
    echo "Checking variable: $name"

    # Check if the name is in ignoredNames
    ignore=false
    for ignoredName in ${ignoredNames[@]}; do
        if [ "$name" == "$ignoredName" ]; then
            ignore=true
            echo "Ignoring variable: $name"
            break
        fi
    done

    if [ "$ignore" == true ]; then
        continue
    fi

    found=false
    for env in $envLines; do
        if [ "$env" == "$name" ]; then
            found=true
            echo "Variable found in environment: $name"
            break
        fi
    done

    # Add to missing only if it's in the names array
    if [ "$found" == false ]; then
        if [[ ! " ${names[@]} " =~ " ${name} " ]]; then
            if [[ ! " ${missing[*]} " =~ " ${name} " ]]; then
                missing+=($name)
                echo "Missing variable: $name"
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
