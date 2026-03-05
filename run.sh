#!/bin/bash
cd "$(dirname "$0")"
source ./config.sh

# Load API keys from .env if it exists
if [ -f .env ]; then
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        key="${line%%=*}"
        value="${line#*=}"
        export "$key=$value"
    done < .env
fi

if [ -z "$OPENAI_API_KEY" ]; then
    echo "WARNING: OPENAI_API_KEY is not set. Check your .env file."
fi

[ ! -d "$APP_NAME.app" ] && ./build.sh

"$APP_NAME.app/Contents/MacOS/$APP_NAME" &
