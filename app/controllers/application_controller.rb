unless api_only?
  insert_into_file 'app/controllers/application_controller.rb', before: /^end/ do
    <<-RUBY
    protect_from_forgery with: :exception
    RUBY
  end
end