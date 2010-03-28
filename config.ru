require 'rubygems'
require 'sinatra'
require 'fourrific'

set :environment => :development
enable :sessions

run Sinatra::Application