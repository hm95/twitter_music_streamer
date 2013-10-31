require 'tweetstream'
require 'json'

TweetStream.configure do |config|
  config.consumer_key       = ''
  config.consumer_secret    = 'E6ez9zMRPf8szb48zkim9PNqnh3W6B1ZH5C5YjMc'
  config.oauth_token        = '410515711-eCMTmOli9tYZu8kZSrL4OWXyN1uVaCHQjnWC8aea'
  config.oauth_token_secret = '3tREvBfdKRdlaDcut60EIBGcsNCKaEWLsNhawl83ZK0'
  config.auth_method        = :oauth
end

time_handle = "#{Time.new.day}-#{Time.new.month}-#{Time.new.year}"

if !File.directory?(time_handle)
  Dir.mkdir(File.join(Dir.pwd, time_handle))
end

file_handle = "#{time_handle}/#{Time.new.day}-#{Time.new.month}-#{Time.new.year}-#{Time.new.hour}-#{Time.new.min}-#{Time.new.sec}"
line_number = 0
line_limit = 500

list_tweets = []
TweetStream::Client.new.track('youtube') do |status|
  json = {}
  begin
    status.attrs.each do |name, val|
      json[name] = val
  end

    list_tweets.push(json.to_json)
    line_number += 1
    
    if line_number >= line_limit
      File.open("#{file_handle}.tweets", 'a') { |f|
        f.write(list_tweets.to_json)
        f.write("\n")
      }

      list_tweets = [] 

      line_number = 0
      time_handle = "#{Time.new.day}-#{Time.new.month}-#{Time.new.year}"

      if !File.directory?(time_handle)
        Dir.mkdir(File.join(Dir.pwd, time_handle))
      end

      file_handle = "#{time_handle}/#{Time.new.day}-#{Time.new.month}-#{Time.new.year}-#{Time.new.hour}-#{Time.new.min}-#{Time.new.sec}"
    end
  rescue
    p "FAIL"
  end

end
