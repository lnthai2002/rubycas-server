require "rvm/capistrano"                                        #use RVM
require "bundler/capistrano"                                    #use bundler
default_run_options[:pty] = true                                #must be set for the password prompt from git to work

set :scm, "git"                                                 #deploy from git repository
set :repository, "git@github.com:lnthai2002/rubycas-server.git" #location of repository
set :ssh_options, {:forward_agent => true}                      #use ssh key when deploy
set :deploy_via, :remote_cache                                  #dont clone repo each deployment but pull difference only
set :keep_releases, 2                                           #keep maximum 2 release

require 'capistrano/ext/multistage'                             #multi-stage deployment
set :stages, %w(production)
set :default_stage, "production"

set :application, "cas"                                         #name of application

namespace :deploy do
  after "deploy:update_code" , "deploy:copy_configuration"

  task :copy_configuration do
    run "cp #{config_loc}/#{rails_env}.config.yml #{release_path}/config.yml"
  end

  desc "Restart passenger with restart.txt"
  task :restart, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

=begin
require "rvm/capistrano"
require "bundler/capistrano" #not recommend use this because development and deployment on different platform(32b,64b) may cause problem installing gem due to missing ARCHFLAGS=
#load "deploy/assets"

#declare multi-stage deployment
require 'capistrano/ext/multistage'
set :stages, %w(production)
set :default_stage, "production"

set :application, "cas"

#declare repository
set :scm,        :git
set :repository, "git@github.com:lnthai2002/rubycas-server.git"
set :migrate_target, :current
set :use_sudo, false
set :ssh_options, {:forward_agent => true}

#overive release variable with current
set(:latest_release)  { fetch(:current_path) }
set(:release_path)    { fetch(:current_path) }
set(:current_release) { fetch(:current_path) }

#overive revision with git version
set(:current_revision)  { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:latest_revision)   { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:previous_revision) { capture("cd #{current_path}; git rev-parse --short HEAD@{1}").strip }

#default_run_options[:shell] = 'bash'

namespace :deploy do

  desc "Deploy and restart"
  task :default do
    update
    restart
  end

  desc "Setup git base deployment, no releases dir"
  task :setup, :except => { :no_release => true } do
    dirs = [deploy_to, shared_path]
    dirs += shared_children.map { |d| File.join(shared_path, d) }
    run "#{try_sudo} mkdir -p #{dirs.join(' ')} && #{try_sudo} chmod g+w #{dirs.join(' ')}"
    run "git clone #{repository} #{current_path}"
  end
  
  task :cold do
    update
    migrate
  end
  
  task :update do
    transaction do
      update_code
    end
  end

  desc "Update the deployed code."
  task :update_code, :except => { :no_release => true } do
    run "cd #{current_path}; git fetch origin; git reset --hard #{branch}"
    finalize_update
  end
  
  desc "Update the database (overwritten to avoid symlink)"
  task :migrations do
    transaction do
      update_code
    end
    migrate
    restart
  end
  
  desc "Restart passenger with restart.txt"
  task :restart, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :copy_configuration do
    run "cp #{config_loc}/#{rails_env}.config.yml #{release_path}/config.yml"
  end
  after "deploy:update_code" , "deploy:copy_configuration"

  namespace :rollback do
    desc "Moves the repo back to the previous version of HEAD"
    task :repo, :except => { :no_release => true } do
      set :branch, "HEAD@{1}"
      deploy.default
    end
    
    desc "Rewrite reflog so HEAD@{1} will continue to point to at the next previous release."
    task :cleanup, :except => { :no_release => true } do
      run "cd #{current_path}; git reflog delete --rewrite HEAD@{1}; git reflog delete --rewrite HEAD@{1}"
    end
    
    desc "Rolls back to the previously deployed version."
    task :default do
      rollback.repo
      rollback.cleanup
    end
  end
end

def run_rake(cmd)
  run "cd #{current_path}; #{rake} #{cmd}"
end
=end