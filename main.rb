require 'sinatra'
require 'sass'
require_relative 'song.rb'
require 'v8'
require 'coffee-script'

configure :development do
  DataMapper.setup(:default,"sqlite3://#{Dir.pwd}/development.rb")
end

configure :production do
  DataMapper.setup(:default, ENV['DATABASE_URL'])
end

configure do
  enable :sessions
  set :username, 'frank'
  set :password, 'sinatra'
  set :session_secret, '99f4eea00f32191ee279d1c75aa27b67'
end

# helpers do
#   def css(*stylesheets)
#     stylesheets.map do |stylesheet|
#       "<link href=#{stylesheet}.css media='screen projection' rel='stylesheet'>"
#     end.join
#   end
# end

get '/styles.css' do
  scss :styles
end

get '/javascripts/application.js' do
  coffee :application
end

get '/login' do
  erb :login
end

post '/login' do
  if params[:username] == settings.username && params[:password] == settings.password
    session[:admin] = true
    redirect to('/songs')
  else
    erb :login
  end
end

get '/logout' do
  session.clear
  redirect to('/login')
end

get '/' do
  erb :home
end

get '/about' do
  @title = "All about This Website"
  erb :about
end

get '/contact' do
  erb :contact
end

not_found do
  erb :not_found
end

get '/songs' do
  redirect to('/login') unless session[:admin]
  @songs = Song.all
  erb :songs
end

get '/songs/new' do
  halt(401, 'Not Authorised') unless session[:admin]
  @song = Song.new
  erb :new_song
end

get '/songs/:id' do
  @song = Song.get(params[:id])
  erb :show_song
end

post '/songs' do
  song = Song.create(params[:song])
  redirect to("/songs/#{song.id}")
end

get '/songs/:id/edit' do
  halt(401, 'Not Authorised') unless session[:admin]
  @song = Song.get(params[:id])
  erb :edit_song
end

put '/songs/:id' do
  halt(401, 'Not Authorised') unless session[:admin]
  song = Song.get(params[:id])
  song.update(params[:song])
  redirect to("/songs/#{song.id}")
end

delete '/songs/:id' do
  halt(401, 'Not Authorised') unless session[:admin]
  Song.get(params[:id]).destroy
  redirect to('/songs')
end

post '/songs/:id/like' do
  @song = Song.get(params[:id])
  @song.likes = @song.likes.next
  @song.save
  redirect to "/songs/#{@song.id}"
  unless request.xhr?
    erb :like
  end
end