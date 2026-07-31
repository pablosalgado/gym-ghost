require 'rails_helper'

RSpec.describe 'Sentry Initializer' do
  after do
    ENV.delete('SENTRY_DSN')
    ENV.delete('SENTRY_ENVIRONMENT')
    ENV.delete('SENTRY_TRACES_SAMPLE_RATE')
    Sentry.close if defined?(Sentry) && Sentry.initialized?
  end

  it 'does not initialize Sentry when SENTRY_DSN is blank' do
    ENV['SENTRY_DSN'] = ''
    load Rails.root.join('config/initializers/sentry.rb')
    expect(Sentry.initialized?).to be(false)
  end

  it 'initializes Sentry when SENTRY_DSN is present' do
    ENV['SENTRY_DSN'] = 'https://public@sentry.example.com/1'
    ENV['SENTRY_ENVIRONMENT'] = 'test-env'
    ENV['SENTRY_TRACES_SAMPLE_RATE'] = '1.0'
    load Rails.root.join('config/initializers/sentry.rb')
    expect(Sentry.initialized?).to be(true)
    expect(Sentry.configuration.dsn.to_s).to eq('https://public@sentry.example.com/1')
    expect(Sentry.configuration.environment).to eq('test-env')
    expect(Sentry.configuration.traces_sample_rate).to eq(1.0)
  end
end
