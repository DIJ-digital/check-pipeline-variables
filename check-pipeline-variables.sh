#!/bin/bash

envContents=$(<.env.example)
yamlContents=$(<bitbucket-pipelines.yml)

contents="$envContents$yamlContents"

names=()

while read -r line; do
    if [[ $line =~ \$\{[\w]*\} ]]; then
        lastPart="${line#*\{}"
        name="${lastPart%\}}"
        names+=("$name")
    fi
done <<< "$contents"

result=$(printenv)

IFS=$'\n' read -ra envLines <<< "$result"

for i in "${!envLines[@]}"; do
    envLines[$i]=${envLines[$i]%%=*}
done

missing=()
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
fi

