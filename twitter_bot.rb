require "twitter"
require 'open-uri'
require 'nokogiri'

class Forecast
  def initialize(url)
    charset = nil
    html = open(url) do |f|
      charset = f.charset
      f.read
    end
    @doc = Nokogiri::HTML.parse(html, nil, charset)
  end

  def getInfo
    p @doc.xpath('//section[@class="section-wrap"]').css('h2').inner_text.insert(-12, " ")
  end

  def getForecast(path)
    node =  @doc.xpath(path)
    date = node.css('h3.left-style').inner_text
    date.slice!(-4, 4)
    weather = node.css('p.weather-telop').inner_text
    max_temp = node.css('dd.high-temp.temp').inner_text
    min_temp = node.css('dd.low-temp.temp').inner_text

    forecast_info = "#{date}" + "\n" + "天気: #{weather}\n" + "最高気温: #{max_temp}\n" + "最低気温: #{min_temp}\n"

    p forecast_info
  end
end

class Bot
  def initialize()
    @client = Twitter::REST::Client.new do | config |
      config.consumer_key = "your consumer key"
      config.consumer_secret = "your consumer secret"
      config.access_token = "your access token"
      config.access_token_secret = "your access token secret"
    end
    @init = 0
  end

  def getForecastAndReport(user_name, current_hour, url)
    @f1 = Forecast.new(url)
    info = @f1.getInfo

    today_info = @f1.getForecast('//section[@class="today-weather"]')
    tomorrow_info = @f1.getForecast('//section[@class="tomorrow-weather"]')

    tweet = "@" + user_name + " " + current_hour.to_i.to_s + "時だよ" + "\n" + info + "\n\n" + today_info + "\n\n" + tomorrow_info
    @client.update(tweet)
    puts user_name + " に天気予報を送信しました."
#    ledNotification
  end

  def getUserOneTweet(user_name)
    timeline = @client.user_timeline(user_name).first
    puts user_name + " のツイートを取得しました."
    puts getTime(timeline.id).strftime("%Y-%m-%d %H:%M:%S.%L %Z")
    p @client.status(timeline.id).text
  end

  def getTime(id)
    Time.at(((id.to_i >> 22) + 1288834974657) / 1000.0)
  end

  def getCurrentHour
    Time.now.strftime("%H")
  end

  def tweetJudge(user_name, url)
    current_tweet = getUserOneTweet(user_name)
    current_hour = getCurrentHour
    if @init == 1
      if current_tweet != @previous_tweet
        puts user_name + " が新しいツイートをしました."
        monomaneSend(user_name, current_tweet)
      end
      if current_hour != @previous_hour
        puts current_hour + "時になりました."
        #timeReport(user_name, current_hour)
        case current_hour
        when '07', '11', '19', '23' then
          getForecastAndReport(user_name, current_hour, url)
        end
      end
    end
    @previous_tweet = current_tweet
    @previous_hour = current_hour
    @init = 1
  end

  def monomaneSend(user_name, current_tweet)
    if current_tweet.include?("@")
      puts "巻き込みリプを回避しました."
    else
      tweet = "@" + user_name + " " + current_tweet
      @client.update(tweet)
      puts user_name + " にツイートを送信しました."
#      ledNotification
    end
  end

  def timeReport(user_name, current_hour)
    tweet = "@" + user_name + " " + current_hour.to_i.to_s + "時だよ"
    @client.update(tweet)
    puts user_name + " に時報を送信しました." 
#    ledNotification
  end
  
#  def ledNotification
#    %x(cd ~/myled && ./led_on.sh && cd -)
#    sleep 6
#    %x(cd ~/myled && ./led_off.sh && cd -)
#  end
end

b1 = Bot.new()
b2 = Bot.new()
b3 = Bot.new()
b4 = Bot.new()

while true
  # ターゲット1, 船橋市
  b1.tweetJudge('target Twitter ID', 'https://tenki.jp/forecast/3/15/4510/12204/')
  puts

  # ターゲット2, 川崎市
  b2.tweetJudge('target Twitter ID', 'https://tenki.jp/forecast/3/17/4610/14130/')
  puts

  sleep 6 
end
