#!/bin/sh

if [ -d "/config" ]; then
    cp /app/config/prod.exs /config/config.ref.exs

    if [ -f "/config/config.exs" ]; then
        cp /config/config.exs /app/prod.exs
    fi
fi

mix phx.digest

$1