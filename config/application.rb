insert_into_file 'config/application.rb', before: /^  end/ do
  <<-'RUBY'
    # Use sidekiq to process Active Jobs (e.g. ActionMailer's deliver_later)
    config.active_job.queue_adapter = :sidekiq
  RUBY
end
