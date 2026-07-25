Rails.application.config.after_initialize do
  SyncFacilitiesJob.perform_later unless Rails.env.test?
end
