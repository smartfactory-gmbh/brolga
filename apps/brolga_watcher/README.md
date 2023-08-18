# BrolgaWatcher

This app contains the logic for running periodic watchers on targets
setup in the Brolga app. Whenever a monitor is getting created/updated/deleted.
the corresponding watcher process is getting started/stopped/restarted here

### Future considerations

Since there is a cross dependency link between this app and `Brolga`,
we may consider merging these two applications. Currently such dependencies are
working, but may confuse some code quality tools

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `brolga_watcher` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:brolga_watcher, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/brolga_watcher>.

