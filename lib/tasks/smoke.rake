# frozen_string_literal: true

namespace :spec do
  desc <<~DESC
    Run smoke tests against a live gym website.

    Required environment variables:
      SMOKE_GYM_URL       – full URL of the gym web app
      SMOKE_GYM_USERNAME  – login e-mail
      SMOKE_GYM_PASSWORD  – login password

    Example:
      SMOKE_GYM_URL=https://gym.example.com \\
      SMOKE_GYM_USERNAME=you@example.com \\
      SMOKE_GYM_PASSWORD=secret \\
        bundle exec rake spec:smoke
  DESC
  task :smoke do
    %w[SMOKE_GYM_URL SMOKE_GYM_USERNAME SMOKE_GYM_PASSWORD].each do |var|
      abort "Error: #{var} environment variable is required." unless ENV[var]
    end

    exec "bundle exec rspec spec/smoke --tag smoke --format documentation"
  end
end
