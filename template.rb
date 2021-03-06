require 'fileutils'
require 'shellwords'
require "json"

RAILS_REQUIREMENT = '~> 6.1.0'.freeze

def apply_template!
  react if api_only?

  assert_minimum_rails_version
  assert_valid_options
  assert_postgresql
  add_template_repository_to_source_path

  # We're going to handle bundler and webpacker ourselves.
  # Setting these options will prevent Rails from running them unnecessarily.
  # self.options = options.merge(
  #   skip_webpack_install: true
  # )

  template 'Gemfile.tt', force: true

  template 'README.md.tt', force: true
  remove_file 'README.rdoc'

  copy_file 'editorconfig', '.editorconfig'
  copy_file 'gitignore', '.gitignore', force: true
  copy_file 'dependabot.yml.tt', '.github/dependabot.yml', force: true
  template 'ruby-version.tt', '.ruby-version', force: true
  remove_file 'package.json'

  # Rspec
  remove_dir 'test'
  copy_file 'rspec', '.rspec'
  directory 'spec'

  apply 'Rakefile.rb'

  apply 'app/template.rb' unless api_only?
  directory("app/assets/", "app/assets/") if api_only?

  apply 'bin/template.rb'
  apply 'circleci/template.rb'
  apply 'config/template.rb'
  apply 'doc/template.rb'
  apply 'lib/template.rb'

  # Caddy
  template 'Caddyfile.tt', force: true

  # Docker
  template 'Dockerfile.dev', 'Dockerfile'
  template 'Dockerfile.release.tt', 'Dockerfile.release'
  copy_file 'docker-entrypoint.sh'
  copy_file 'docker-compose.yml'
  copy_file 'env.example', '.env.example'

  # Api
  if api_only?
    copy_file 'app/controllers/api_controller.rb', 'app/controllers/api_controller.rb' 
    copy_file 'app/controllers/users/registrations_controller.rb', 'app/controllers/users/registrations_controller.rb'
  end
  # apply "variants/bootstrap/template.rb" if apply_bootstrap?

  git :init unless preexisting_git_repo?
  empty_directory '.git/safe'

  run_with_clean_bundler_env 'bin/setup'
  run_with_clean_bundler_env "bundle exec spring binstub --all"
  install_devise
  install_cancancan if @cancancan
  install_active_admin if @active_admin
  install_crono if @crono
  run_with_clean_bundler_env "bundle update"
  install_webpacker unless api_only? 
  
  
  binstubs = %w[ annotate brakeman bundler bundler-audit rubocop ]
  run_with_clean_bundler_env "bundle binstubs #{binstubs.join(' ')} --force"
  
  template 'rubocop.yml.tt', '.rubocop.yml'
  run_rubocop_autocorrections
  
  tailwind unless api_only?
  install_tailwind if @tailwind
  
  unless react
    # Caddy
    template 'Caddyfile.tt', force: true

    # Docker
    template 'base.Dockerfile.tt', 'base.Dockerfile'
    template 'Dockerfile.dev', 'Dockerfile'
    template 'Dockerfile.release.tt', 'Dockerfile.release'
    copy_file 'docker-entrypoint.sh'
    copy_file 'docker-compose.yml'
    copy_file 'env.example', '.env.example'
    copy_file 'db/seeds.rb', force: true
  end

  # unless any_local_git_commits?
  #   git add: '-A .'
  #   git commit: "-n -m 'Set up project'"
  #   if git_repo_specified?
  #     git remote: "add origin #{git_repo_url.shellescape}"
  #     git push: '-u origin --all'
  #   end
  # end
end

def apply_react!
  empty_directory 'rails'
  run "mv `\ls -1 | grep -v -E 'rails'` rails/"
  run 'mv .* rails/ || :'
  run "npx create-react-app #{@app_name}"
  run "mv #{@app_name} react"
  run "sed -i.bak 's/\"start\": \"react-scripts start\",/\"start\": \"PORT=8080 react-scripts start\",/g' react/package.json"

  # Caddy
  template 'Caddyfile.tt', force: true

  # Docker
  template 'base.Dockerfile.tt', 'rails/base.Dockerfile'
  template 'Dockerfile.dev', 'rails/Dockerfile'
  copy_file 'docker-entrypoint.sh', 'rails/docker-entrypoint.sh'
  copy_file 'Dockerfile.react.dev', 'react/Dockerfile'
  copy_file 'react-run.sh', 'react/run.sh'
  copy_file 'docker-compose.react.yml', 'docker-compose.yml'
  copy_file 'env.example', '.env.example'
  copy_file 'db/seeds.rb', 'rails/db/seeds.rb', force: true
end

# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require 'tmpdir'
    source_paths.unshift(tempdir = Dir.mktmpdir('rails-template-'))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      '--quiet',
      'https://github.com/leikir/rails-template.git',
      tempdir
    ].map(&:shellescape).join(' ')

    if (branch = __FILE__[%r{rails-template/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def assert_minimum_rails_version
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  prompt = "This template requires Rails #{RAILS_REQUIREMENT}. "\
           "You are using #{rails_version}. Continue anyway?"
  exit 1 if no?(prompt)
end

# Bail out if user has passed in contradictory generator options.
def assert_valid_options
  valid_options = {
    skip_gemfile: false,
    skip_git: false,
    skip_test_unit: false,
    edge: false
  }
  valid_options.each do |key, expected|
    next unless options.key?(key)
    actual = options[key]
    unless actual == expected
      fail Rails::Generators::Error, "Unsupported option: #{key}=#{actual}"
    end
  end
end

def assert_postgresql
  return if IO.read("Gemfile") =~ /^\s*gem ['"]pg['"]/

  fail Rails::Generators::Error,
       'This template requires PostgreSQL, '\
       'but the pg gem is not present in your Gemfile.'
end

def git_repo_url
  @git_repo_url ||=
    ask_with_default('What is the git remote URL for this project?', :blue, 'skip')
end

def production_hostname
  @production_hostname ||=
    ask_with_default('Production hostname?', :blue, 'example.com')
end

def gemfile_requirement(name)
  @original_gemfile ||= IO.read('Gemfile')
  req = @original_gemfile[/gem\s+['"]#{name}['"]\s*(,[><~= \t\d\.\w'"]*)?.*$/, 1]
  req && req.gsub("'", %(")).strip.sub(/^,\s*"/, ', "')
end

def ask_with_default(question, color, default)
  return default unless $stdin.tty?

  question = (question.split('?') << " [#{default}]?").join
  answer = ask(question, color)
  answer.to_s.strip.empty? ? default : answer
end

def git_repo_specified?
  git_repo_url != 'skip' && !git_repo_url.strip.empty?
end

def preexisting_git_repo?
  @preexisting_git_repo ||= (File.exist?('.git') || :nope)
  @preexisting_git_repo == true
end

def any_local_git_commits?
  system('git log &> /dev/null')
end

def apply_bootstrap?
  ask_with_default('Use Bootstrap gems, layouts, views, etc.?', :blue, 'no')\
    =~ /^y(es)?/i
end

def run_with_clean_bundler_env(cmd)
  success = if defined?(Bundler)
              Bundler.with_clean_env { run(cmd) }
            else
              run(cmd)
            end
  unless success
    puts "Command failed, exiting: #{cmd}"
    exit(1)
  end
end

def run_rubocop_autocorrections
  run_with_clean_bundler_env 'bin/rubocop -a --fail-level A > /dev/null || true'
end

def install_devise
  run_with_clean_bundler_env 'bin/rails generate devise:install'
  run_with_clean_bundler_env 'bin/rails generate devise User'
  rails_command 'db:migrate'
  unless api_only?
    run_with_clean_bundler_env 'bin/rails generate devise:views'
    run 'erb2slim ./app/views/devise -d'
  end
  apply 'config/initializers/devise.rb'
  if api_only?
    gsub_file 'config/routes.rb', '  devise_for :users' do
      "  devise_for :users,
      controllers: {
        registrations: 'users/registrations'
      },
      defaults: { format: :json }"
    end
  end
end

def cancancan
  @cancancan ||=
    yes?('Add CanCanCan to the Gemfile ? (default: no)')
end

def active_admin
  @active_admin ||= 
    yes?('Add ActiveAdmin to the Gemfile ? (default: no)') unless api_only?
end

def crono
  @crono ||=
    yes?('Add Crono to the Gemfile ? (default: no)')
end

def tailwind
  @tailwind ||=
    yes?('Add Tailwind to the Gemfile ? (default: no)')
end

def webpacker
  @webpacker ||=
    yes?('Add Webpacker to the Gemfile ? (default: no)')
end

def install_cancancan
  run_with_clean_bundler_env 'bin/rails generate cancan:ability'
end

def install_tailwind
  run_with_clean_bundler_env 'yarn add tailwindcss@npm:@tailwindcss/postcss7-compat @tailwindcss/postcss7-compat postcss@^7 autoprefixer@^9 rails-ujs turbolinks'
  run "mkdir -p app/javascript/stylesheets && touch app/javascript/stylesheets/application.scss"
  run "echo '@import \"tailwindcss/base\";\n@import \"tailwindcss/components\";\n@import \"tailwindcss/utilities\";' >> 'app/javascript/stylesheets/application.scss'"
  run "echo 'require(\"stylesheets/application.scss\")' >> 'app/javascript/packs/application.js'"
  File.open('postcss.config.js', 'r+') do |file|
    lines = file.each_line.to_a
    lines[1] = "plugins: [\n\trequire('tailwindcss'),\n\trequire('autoprefixer'),\n"
    file.rewind
    file.write(lines.join)
  end
  run_with_clean_bundler_env 'yarn tailwind init'
end

def install_webpacker
  run_with_clean_bundler_env "bin/rails webpacker:install"
end

def install_active_admin
  run_with_clean_bundler_env 'bin/rails generate active_admin:install'
end

def install_crono
  run_with_clean_bundler_env 'bin/rails generate crono:install'
  new_header="class CreateCronoJobs < ActiveRecord::Migration[6.1]"
  file_name = Dir.glob(File.join('db/migrate/', '*.*')).max { |a,b| File.ctime(a) <=> File.ctime(b) }
  run "sed -i.bak \"1 s/^.*$/#{new_header}/\" #{file_name}"
  rails_command 'db:migrate'
end

def react
  @react ||=
    yes?('Use React ? (default: no)')
end

def api_only?
  !!options['api']
end

apply_template!
apply_react! if react
