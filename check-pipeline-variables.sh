#!/bin/bash

# Check if an argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <environment-file>"
    exit 1
fi

# Use the first argument as the environment file
envFile=$1

# Read contents of the provided environment file
if [ -f "$envFile" ]; then
    envContents=$(<"$envFile")
else
    echo "Environment file not found: $envFile"
    exit 1
fi

yamlContents=$(<bitbucket-pipelines.yml)

contents="$envContents$yamlContents"

# Initialize the names array properly
declare -a names

while read -r line; do
    if [[ $line =~ \$\{[\w]*\} ]]; then
        lastPart="${line#*\{}"
        name="${lastPart%\}}"
        names+=("$name")
    fi
done <<< "$contents"

result=$(printenv)

IFS=$'\n' read -ra envLines <<< "$result"

# Process the envLines array
for i in "${!envLines[@]}"; do
    envLines[$i]=${envLines[$i]%%=*}
done

# Initialize the missing array properly
declare -a missing
ignoredNames=('APP_KEY' 'APP_NAME')

for name in "${names[@]}"; do
    if [[ " ${ignoredNames[@]} " =~ " $name " ]]; then
        continue
    fi

    if [[ ! " ${envLines[@]} " =~ " $name " ]]; then
        missing+=("$name")
    fi
done

if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing variables: ${missing[@]}"
    exit 1
else
    echo "No missing variables found."
fi
