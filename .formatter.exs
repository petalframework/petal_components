# Used by "mix format" and to export configuration.
export_locals_without_parens = [
  attr: 3,
  slot: 2,
  slot: 3,
  plug: 1,
  plug: 2,
  forward: 2,
  forward: 3,
  forward: 4,
  match: 2,
  match: 3,
  get: 2,
  get: 3,
  head: 2,
  head: 3,
  post: 2,
  post: 3,
  put: 2,
  put: 3,
  patch: 2,
  patch: 3,
  delete: 2,
  delete: 3,
  options: 2,
  options: 3,
  embed_templates: 2
]

[
  import_deps: [:phoenix],
  inputs: ["*.{heex,ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{heex,ex,exs}"],
  locals_without_parens: export_locals_without_parens,
  export: [locals_without_parens: export_locals_without_parens],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter]
]
