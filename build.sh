#!/bin/bash

echo "Building dsh..."
odin build src -out:dsh -o:speed

if [[ $? -eq 0 ]]; then
    echo "Build succeeded"
    execute ./dsh
else
    echo "Build failed"
fi
