lock "~> 3.16.0"

set :application, 'lodestone'
set :repo_url,    'https://github.com/mattantonelli/lodestone'
set :branch,      ENV['BRANCH_NAME'] || 'master'
set :deploy_to,   '/var/rails/lodestone'
set :default_env, { path: '$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH' }

# rbenv
set :rbenv_type, :user
set :rbenv_ruby, '3.1.0'

namespace :deploy do
  desc 'Create symlinks'
  after :updating, :symlink do
    on roles(:app) do
      # Application credentials
      execute :ln, '-s', shared_path.join('master.key'), release_path.join('config/master.key')

      # Persisted logs
      execute :ln, '-s', shared_path.join("log/#{fetch(:rails_env)}.log"), release_path.join("log/#{fetch(:rails_env)}.log")
      execute :ln, '-s', shared_path.join('log/whenever.log'), release_path.join('log/whenever.log')
    end
  end

  desc 'Restart application'
  after :publishing, :restart do
    on roles(:app) do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end
end
