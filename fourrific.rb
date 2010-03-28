require 'rubygems'
require 'sinatra'
require File.dirname(__FILE__) + '/base'

enable :sessions

get '/' do
	
	if params[:oauth_token]
		h = Fourrific::Authorize.new
		t = h.access_token(params[:oauth_token],session[:request_secret])
		session[:token] = t[:token]
		session[:secret] = t[:secret]
	
	elsif session[:token].nil?
		redirect '/login'	
	end
	
	c = Fourrific::Checkins.new(session[:token],session[:secret])
	
	@c = c.friends
	
	erb :index

end

get '/login' do
	
	h = Fourrific::Authorize.new
	t = h.get_tokens
	
	session[:request_token] = t[:request_token]
	session[:request_secret] = t[:secret]
	@url = t[:url]
	
	redirect "#{@url}"
	erb :login
end