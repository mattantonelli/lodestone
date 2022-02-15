require 'capistrano/setup'
require 'capistrano/deploy'
require 'capistrano/rbenv'
require 'capistrano/bundler'
require 'capistrano/rails'

# TODO
# Uncomment this when we are ready to migrate. Otherwise we risk the existing
# rate limit issues when we try to fetch alongside the Sinatra app.
#require 'whenever/capistrano'

require 'capistrano/scm/git'
install_plugin Capistrano::SCM::Git

Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
