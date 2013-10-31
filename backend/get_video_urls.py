import os, json
from pprint import pprint
from datetime import datetime, timedelta

# filtering out music
from apiclient.discovery import build
from optparse import OptionParser 

# writing to postgresql database
import psycopg2
import pprint

# making our database result
from simplejson.compat import StringIO
import re

# parallelization
from apiclient.http import BatchHttpRequest

conn_string = "dbname='dbhtagme8iv8ep' host='ec2-107-21-106-181.compute-1.amazonaws.com' user='' password='' port='5432'"
conn = psycopg2.connect(conn_string)
cursor = conn.cursor()

DEVELOPER_KEY = "AIzaSyAXcbkSvi_Uh0BMrVOETsNfJFQG-n8EUDM"
YOUTUBE_API_SERVICE_NAME = "youtube"
YOUTUBE_API_VERSION = "v3"
youtube = build(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION,
  developerKey=DEVELOPER_KEY)

unique_link_table = {}
language_table = {}
geo_table = {}
retweet_table = {}
max_retweet_table = {}
trending_table = {}
time_of_day_table = {}

list_popular_music_videos = []
list_popular_music_ids = []

list_trending_music_videos = []
list_trending_music_ids = []

def process_result(request_id, response, exception):
  if exception is None:
    if len(response["items"]) > 0 and response["items"][0]["snippet"]["categoryId"] == "10":
      list_popular_music_videos.append(response)

def process_trending(request_id, response, exception):
  if exception is None:
    if len(response["items"]) > 0 and response["items"][0]["snippet"]["categoryId"] == "10":
      list_trending_music_videos.append(response)

def print_popular_videos_with_analytics():
  for table in unique_link_table:
    num_batch = 0
    batch = BatchHttpRequest()

    for video_id in sorted(unique_link_table[table], key=unique_link_table[table].get, reverse=True):
      if num_batch >= 1000:
        break

      if len(list_popular_music_videos) >= 20:
        break

      batch.add(youtube.videos().list(id=video_id, part="snippet"), callback=process_result)
      num_batch += 1

    try:
      print "not missing http"
      batch.execute()
    except ValueError:
      print "missing http"

    if len(list_popular_music_videos) >= 20:
      for video in list_popular_music_videos[:50]:
        if len(video["items"]) > 0:
          list_popular_music_ids.append((video["items"][0]["id"], video["items"][0]["snippet"]["title"]))

      write_popular_to_database(table, list_popular_music_ids)
      del list_popular_music_ids[:]

def print_trending_videos_with_analytics():
  num_batch = 0
  batch = BatchHttpRequest()

  today = datetime.today() - timedelta(1)
  yesterday = today - timedelta(1)

  today_table_name = "./{0}-{1}-{2}".format(today.day, today.month, today.year)
  yesterday_table_name = "./{0}-{1}-{2}".format(yesterday.day, yesterday.month, yesterday.year)

  today_table = unique_link_table[today_table_name]
  yesterday_table = unique_link_table[yesterday_table_name]

  trending_table = calculate_percent_diffs(yesterday_table, today_table)

  for video in sorted(trending_table, key=trending_table.get, reverse=True):
    if num_batch >= 1000:
      break
          
    if len(list_trending_music_videos) >= 20:
      break

    batch.add(youtube.videos().list(id=video, part="snippet"), callback=process_trending)
    num_batch += 1

  try:
    print "not missing http"
    batch.execute()
  except ValueError:
    print "missing http"

  if len(list_trending_music_videos) >= 20:
    for video in list_trending_music_videos[:50]:
      if len(video["items"]) > 0:
        list_trending_music_ids.append((video["items"][0]["id"], video["items"][0]["snippet"]["title"]))

  write_trending_to_database(today_table_name, list_trending_music_ids)
  del list_trending_music_ids[:]

def write_trending_to_database(table, list_trending_music_videos):
    print "writing trending to database"
    video_results_json = []

    for video_id, title in list_trending_music_videos:
      video_json = {}
      video_json["id"] = video_id
      video_json["title"] = title

      if video_id in language_table:
        video_json["language"] = language_table[video_id]
      if video_id in geo_table:
        video_json["geo"] = geo_table[video_id]
      if video_id in retweet_table:
        video_json["retweet_network"] = retweet_table[video_id]
      if video_id in max_retweet_table:
        video_json["num_retweet_was_retweeted"] = max_retweet_table[video_id][0]
        video_json["max_retweet_count"] = max_retweet_table[video_id][1]['text']
      if video_id in time_of_day_table:
        video_json["popular_time"] = time_of_day_table[video_id]
      video_results_json.append(video_json)

    io = StringIO()
    json.dump(video_results_json, io)
    cursor.execute("INSERT into videos VALUES ('%s', 'trending', '%s')" % (table[1:], re.escape(io.getvalue())))
    conn.commit()

def write_popular_to_database(table, list_popular_music_ids):
    print "writing popular to database"
    video_results_json = []

    for video_id, title in list_popular_music_ids:
      video_json = {}
      video_json["id"] = video_id
      video_json["title"] = title

      if video_id in language_table:
        video_json["language"] = language_table[video_id]
      if video_id in geo_table:
        video_json["geo"] = geo_table[video_id]
      if video_id in retweet_table:
        video_json["retweet_network"] = retweet_table[video_id]
      if video_id in max_retweet_table:
        video_json["num_retweet_was_retweeted"] = max_retweet_table[video_id][0]
        video_json["max_retweet_count"] = max_retweet_table[video_id][1]['text']
      if video_id in time_of_day_table:
        video_json["popular_time"] = time_of_day_table[video_id]
      video_results_json.append(video_json)

    io = StringIO()
    json.dump(video_results_json, io)
    cursor.execute("INSERT into videos VALUES ('%s', 'popular', '%s')" % (table[1:], re.escape(io.getvalue())))
    conn.commit()

def add_video_counts_to_table(video_id, root):
  if video_id != "":
    if video_id in unique_link_table[root]:
      unique_link_table[root][video_id] += 1
    else:
      unique_link_table[root][video_id] = 1

def update_unique_counts(video_id, root):
    if root not in unique_link_table:
      unique_link_table[root] = {}
    add_video_counts_to_table(video_id, root)

def update_language_information(tweet, video_id):
  language = tweet['user']['lang']

  if video_id not in language_table:
    language_table[video_id] = {}

  if language in language_table[video_id]:
    language_table[video_id][language] += 1
  else:
    language_table[video_id][language] = 1

def calculate_bucket_of_day(time):
  hour_of_day = int(time.split(' ')[3].split(":")[0])

  if hour_of_day >= 0 and hour_of_day < 5:
    return "Afternoon"
  elif hour_of_day >= 5 and hour_of_day < 11:
    return "Evening"
  elif hour_of_day >= 11 and hour_of_day < 20:
    return "Night"
  elif hour_of_day >= 20 and hour_of_day < 24:
    return "Morning"

def update_time_of_day_information(tweet, video_id):
  time_of_tweet = tweet['created_at']
  time_of_day = calculate_bucket_of_day(time_of_tweet)

  if video_id not in time_of_day_table:
    time_of_day_table[video_id] = {}

  if time_of_day in time_of_day_table[video_id]:
    time_of_day_table[video_id][time_of_day] += 1
  else:
    time_of_day_table[video_id][time_of_day] = 1

def update_geo_information(tweet, video_id):
  geo = tweet['user']['time_zone']
  if geo != None:
    if video_id not in geo_table:
      geo_table[video_id] = {}

    if geo in geo_table[video_id]:
      geo_table[video_id][geo] += 1
    else:
      geo_table[video_id][geo] = 1

def update_retweet_information(tweet, video_id):
  if 'retweeted_status' in tweet:
    retweet_count = tweet['retweeted_status']['retweet_count']

    if video_id not in retweet_table:
      retweet_table[video_id] = retweet_count
    else:
      retweet_table[video_id] += retweet_count

    if video_id not in max_retweet_table:
      max_retweet_table[video_id] = (retweet_count, tweet)
    else:
      if retweet_count > max_retweet_table[video_id][0]:
        max_retweet_table[video_id] = (retweet_count, tweet)

def populate_link_count(filename, root):
  log_file = json.loads(open(os.path.abspath(filename)).read())

  for entry in log_file:
    tweet = json.loads(entry)

    video_id = ""

    for url_entry in tweet['entities']['urls']:
      url = url_entry['expanded_url']
      video_id = ""

      if url.startswith('http://m.youtube.com'):
        try:
          url.index('?v=')
          video_id = url.split('?v=')[-1][:11]
        except:
          pass # Not a video
      elif url.startswith('http://www.youtube.com'):
        try:
          url.index('?v=')
          video_id = url.split('?v=')[-1][:11]
        except ValueError:
          pass # Not a video
      elif url.startswith('http://youtube.com'):
        try:
          url.index('?v=')
          video_id = url.split('?v=')[-1][:11]
        except ValueError:
          pass # Not a video
      elif url.startswith('http://youtu.be'):
        try:
          video_id = url.split('/')[-1][:11]
        except ValueError:
          pass # Not a video
      elif url.startswith('https://www.youtube.com'):
        try:
          url.index('?v=')
          video_id = url.split('?v=')[-1][:11]
        except ValueError:
          pass # Not a video
      elif url.startswith('https://youtube.com'):
        try:
          url.index('?v=')
          video_id = url.split('?v=')[-1][:11]
        except ValueError:
          pass # Not a video

      update_unique_counts(video_id, root)

    if video_id != "":
      update_language_information(tweet, video_id)
      update_geo_information(tweet, video_id)
      update_retweet_information(tweet, video_id)
      update_time_of_day_information(tweet, video_id)

def calculate_percent_diffs(yesterday_table, today_table):
  percent_diff_table = {}

  for video in yesterday_table:
    if video in today_table:
      percent_diff_table[video] = (today_table[video] - yesterday_table[video]) / float(yesterday_table[video])

  return percent_diff_table

if __name__ == "__main__":
  for root, dirs, files in os.walk('.'):
    for file in files:
      if file.endswith('.tweets'):
        populate_link_count(os.path.join(root, file), root)
  print_trending_videos_with_analytics()
  print_popular_videos_with_analytics()
