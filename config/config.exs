# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :foo, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:foo, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

config :apns,
  name: :dev_config,
  apple_host: 'api.development.push.apple.com',
  apple_port: 443,
  certfile: 'cert.pem',
  keyfile: 'key.pem',
#  token_keyfile: "priv/APNsAuthKey_KEYID12345.p8",
  timeout: 10000,

  # APNs Headers

  apns_id: "55d8299a-7b4b-11e7-800f-00163e5e6c0c",
  apns_expiration: 0,
  apns_priority: 10,
  apns_topic: "network.potato.Gratin",
  apns_collapse_id: "potato.messages",

  # Feedback
  feedback_host: 'feedback.push.apple.com',
  feedback_port: 2195

# :apns.connect :cert, :dev_config
# :apns.push_notification :dev_config, "foo", %{aps: %{alert: "test"}}
