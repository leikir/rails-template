gsub_file 'config/initializers/devise.rb',
          'config.password_length = 6..128',
          'config.password_length = 8..128'

if !!options['api']
  gsub_file 'config/initializers/devise.rb',
  '# config.parent_controller = \'DeviseController\'',
  'config.parent_controller = \'ApiController\''  
end

