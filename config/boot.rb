ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

ENV["ATTR_ENCRYPTED_KEY"] ||= "a]3$7!xK9#mP2vQ8wR5tY0bN4dF6gH1j"
