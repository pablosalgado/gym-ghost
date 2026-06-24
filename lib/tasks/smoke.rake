# frozen_string_literal: true

namespace :spec do
  desc <<~DESC
    Run smoke tests against a live gym website using the credentials defined in config/credentials.yml.enc.

    Example:
      bundle exec rake spec:smoke
  DESC
  task :smoke do
    exec "bundle exec rspec spec/smoke --tag smoke --format documentation"
  end
end
