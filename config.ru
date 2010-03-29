require 'rubygems'
require 'sinatra'
require 'fourrific'

set :environment => :production
enable :sessions

run Sinatra::Application