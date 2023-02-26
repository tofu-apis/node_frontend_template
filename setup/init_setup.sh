#!/bin/bash

# The purpose of this script is to initialize
# the local development environment once the
# repo is freshly cloned to allow for an
# immediately working local repo

# Initialize git hooks path
git config core.hooksPath .githooks/

# Initialize the dependencies locally
npm install
