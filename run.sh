#!/bin/bash
cd "$(dirname "$0")"
source ./config.sh

# Load API keys from .env if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

[ ! -d "$APP_NAME.app" ] && ./build.sh

OPENAI_API_KEY="$OPENAI_API_KEY" open "$APP_NAME.app"
