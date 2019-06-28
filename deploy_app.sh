#!/usr/bin/env bash

zip -r app.zip . -x ".*" -x "__MACOSX" -x "genkey" -x "*.code-workspace" -x "deploy_app.sh" -x "app.zip"
