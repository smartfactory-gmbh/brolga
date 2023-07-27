
from elixir:1.15-alpine

COPY . /app
RUN chmod +x /app/.docker/entrypoint.sh
WORKDIR /app

RUN mix deps.get

entrypoint ["/app/.docker/entrypoint.sh"]
CMD ["mix phx.server"]