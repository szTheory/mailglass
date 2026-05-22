import Config

# No dev-only config. mailglass_inbound is a library; host applications supply
# their own repo and provider settings. This file exists so the
# `import_config "#{config_env()}.exs"` in config.exs resolves in the :dev env
# (e.g. when building docs).
