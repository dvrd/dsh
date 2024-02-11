#!/bin/bash

echo "Building wish..."
odin build src -out:target/debug/wish

if [[ $? -eq 0 ]]; then
    echo "Build succeeded"
else
    echo "Build failed"
fi
