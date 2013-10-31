require 'sinatra'
require 'haml'
require 'coffee-script'
require 'sass'
require 'json'
require 'pg'

set :haml, :format => :html5
set :sass, :style => :compact

conn = PG.connect( dbname: 'dbhtagme8iv8ep', host:'ec2-107-21-106-181.compute-1.amazonaws.com', user:'', password:'', port:'5432' )

# Routes: index (popular), trending
get '/' do
  redirect '/popular'
end

get '/popular' do
  haml :popular
end

get '/trending' do
  haml :trending
end

# Load all javascripts
get '/scripts/*.js' do |n|
  coffee :"../assets/javascripts/#{n}"
end

# Load stylesheets
get '/css/*.css' do |n|
  content_type 'text/css', charset: 'utf-8'
  sass :"../assets/stylesheets/#{n}"
end

# Load feeds
get '/popularfeed.json' do
  #content_type :json
  @results = []
  conn.exec( "SELECT result FROM videos where date='#{(DateTime.now).strftime("%Y-%d-%m")}' AND type='popular'" ) do |result|
    result.each do |row|
   	  @results.push(row)
   	end
  end
  @results.to_json
end

get '/trendingfeed.json' do
  #content_type :json
  @results = []
  conn.exec( "SELECT result FROM videos where date='#{(DateTime.now).strftime("%Y-%d-%m")}' AND type='trending'" ) do |result|
    result.each do |row|
   	  @results.push(row)
   	end
  end
  @results.to_json
end
