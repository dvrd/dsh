#!/bin/bash

echo "Building wish..."
odin build src -out:wish -o:speed

if [[ $? -eq 0 ]]; then
    echo "Build succeeded"
    execute ./wish
else
    echo "Build failed"
fi
