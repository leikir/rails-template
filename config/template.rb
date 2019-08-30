apply 'config/application.rb'
copy_file 'config/boot.rb', force: true
template 'config/database.example.yml.tt'
remove_file 'config/database.yml'
remove_file 'config/secrets.yml'
copy_file 'config/sidekiq.yml'

insert_into_file 'config/routes.rb', before: /Rails.application.routes.draw do/ do
  <<-'RUBY'
require 'sidekiq/web'

  RUBY
end
gsub_file 'config/routes.rb', /  # root 'welcome#index'/ do
  "  root 'home#index'"
end

copy_file 'config/initializers/generators.rb'
copy_file 'config/initializers/rollbar.rb'
copy_file 'config/initializers/rotate_log.rb'
copy_file 'config/initializers/version.rb'
copy_file 'config/initializers/sidekiq.rb'

gsub_file 'config/initializers/filter_parameter_logging.rb', /\[:password\]/ do
  '%w[password secret session cookie csrf]'
end

apply 'config/environments/development.rb'
apply 'config/environments/production.rb'
apply 'config/environments/test.rb'

unless api_only?
  route "root 'home#index'"
  route %Q(mount Sidekiq::Web => '/sidekiq' # monitoring console\n)
end
