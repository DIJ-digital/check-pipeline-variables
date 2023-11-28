#!/bin/bash

# Check if file argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <env-file>"
    exit 1
fi

# Get the file from the first argument
envFile="$1"

# Check if file exists
if [ ! -f "$envFile" ]; then
    echo "Error: File '$envFile' not found."
    exit 1
fi

# Read contents of the environment file
envContents=$(cat "$envFile")
yamlContents=$(cat bitbucket-pipelines.yml)

# Combine contents
contents="$envContents $yamlContents"

# Extract environment variable names from contents
names=()
for line in $contents; do
    if [[ $line =~ \$\{[a-zA-Z_][a-zA-Z0-9_]*\} ]]; then
        name=$(echo $line | grep -oP '\$\{\K[a-zA-Z_][a-zA-Z0-9_]*(?=\})')
        names+=($name)
    fi
done

# Get all environment variables
envLines=$(printenv | cut -d '=' -f1)

# Check for missing variables
missing=()
ignoredNames=("APP_KEY" "APP_NAME")

for name in ${names[@]}; do
    # Check if the name is in ignoredNames
    ignore=false
    for ignoredName in ${ignoredNames[@]}; do
        if [ "$name" == "$ignoredName" ]; then
            ignore=true
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
            break
        fi
    done

    if [ "$found" == false ]; then
        # Check if the name is already in the missing array to avoid duplicates
        if [[ ! " ${missing[*]} " =~ " ${name} " ]]; then
            missing+=($name)
        fi
    fi
done

# Throw error if missing variables
if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing variables: ${missing[*]}"
    exit 1
fi
