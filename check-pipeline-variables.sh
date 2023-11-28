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

# Read contents of the environment file and YAML file
envContents=$(cat "$envFile")
yamlContents=$(cat bitbucket-pipelines.yml)

# Combine contents
contents="$envContents $yamlContents"

# Extract environment variable names and their references from contents
declare -A varReferences
for line in $contents; do
    if [[ $line =~ \$\{[a-zA-Z_][a-zA-Z0-9_]*\} ]]; then
        name=$(echo $line | grep -oP '\$\{\K[a-zA-Z_][a-zA-Z0-9_]*(?=\})')
        # Check if there's a reference in the form VARIABLE=${REFERENCE}
        if [[ $line =~ ([a-zA-Z_][a-zA-Z0-9_]*)\=\$\{([a-zA-Z_][a-zA-Z0-9_]*)\} ]]; then
            refName=${BASH_REMATCH[2]}
            varReferences[$name]=$refName
        fi
    fi
done

# Get all environment variables
envLines=$(printenv | cut -d '=' -f1)

# Check for missing variables
missing=()
ignoredNames=("APP_KEY" "APP_NAME")

for name in "${!varReferences[@]}"; do
    # Check if the name is in ignoredNames
    ignore=false
    for ignoredName in "${ignoredNames[@]}"; do
        if [ "$name" == "$ignoredName" ]; then
            ignore=true
            break
        fi
    done

    if [ "$ignore" == true ]; then
        continue
    fi

    # Check if the variable or its reference exists in the environment
    found=false
    ref=${varReferences[$name]}
    for env in $envLines; do
        if [ "$env" == "$name" ] || ([ ! -z "$ref" ] && [ "$env" == "$ref" ]); then
            found=true
            break
        fi
    done

    if [ "$found" == false ]; then
        missing+=($name)
    fi
done

# Throw error if missing variables
if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing variables: ${missing[*]}"
    exit 1
fi