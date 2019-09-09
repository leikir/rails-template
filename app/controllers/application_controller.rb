unless api_only?
  insert_into_file 'app/controllers/application_controller.rb', before: /^end/ do
    <<-RUBY
    protect_from_forgery with: :exception
    RUBY
  end
end

insert_into_file 'app/controllers/application_controller.rb', before: /^end/ do
  <<-RUBY
  before_action :authenticate_user!

  RUBY
end
