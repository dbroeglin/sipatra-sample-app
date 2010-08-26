require 'rubygems'
require 'sinatra/application.rb'
set :run, false
set :environment, :production
run Sinatra::Application
