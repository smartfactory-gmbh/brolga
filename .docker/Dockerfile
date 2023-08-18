
from elixir:1.15-alpine

RUN apk add curl --no-cache

ENV MIX_ENV=prod

COPY . /app
RUN chmod +x /app/.docker/entrypoint.sh
WORKDIR /app

RUN mix deps.get --only prod && mix compile && mix assets.deploy && mix phx.digest

ENTRYPOINT ["/app/.docker/entrypoint.sh"]
CMD ["mix phx.server"]

HEALTHCHECK --interval=5s CMD curl --fail http://localhost:4000 || exit 1