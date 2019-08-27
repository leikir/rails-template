# Assets
copy_file "app/assets/stylesheets/application.scss"
remove_file "app/assets/stylesheets/application.css"
directory "app/assets/javascripts", "app/assets/javascripts"
copy_file "app/assets/config/manifest.js", force: true
remove_dir "app/javascript"

# Controllers
copy_file "app/controllers/home_controller.rb"

# Helpers
copy_file "app/helpers/layout_helper.rb"
copy_file "app/helpers/retina_image_helper.rb"
copy_file "app/views/layouts/application.html.erb", force: true
template "app/views/layouts/base.html.erb.tt"
copy_file "app/views/shared/_flash.html.erb"
copy_file "app/views/home/index.html.erb"
