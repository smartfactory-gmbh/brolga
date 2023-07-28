#!/bin/sh

if [ -d "/config" ]; then
    cp /app/config/prod.exs /config/config.ref.exs

    if [ -f "/config/config.exs" ]; then
        cp /config/config.exs /app/prod.exs
    fi
fi

mix ecto.migrate
mix run apps/brolga/priv/repo/seeds.exs

$1
