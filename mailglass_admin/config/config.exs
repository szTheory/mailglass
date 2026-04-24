import Config

# CONTEXT D-22: pin Tailwind version in the admin package's own config;
# do not track latest blindly. daisyUI pin lives as a file-header comment
# in assets/vendor/daisyui.js (Plan 05 ships that file).
config :tailwind,
  version: "4.1.12",
  default: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Swoosh 1.25+ raises on boot if :api_client is not configured. mailglass
# core pulls Swoosh in transitively; mailglass_admin never sends mail so
# there is nothing to pick here. Disable the client to keep the admin test
# suite bootable. Matches the root mailglass config/config.exs line 15.
config :swoosh, :api_client, false

# Environment-specific config split out for clarity.
if File.exists?(Path.join(__DIR__, "#{config_env()}.exs")) do
  import_config "#{config_env()}.exs"
end
