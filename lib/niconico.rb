require 'json'
require 'open-uri'
require 'net/https'
require 'rexml/document'
require 'active_support'
require 'active_support/core_ext'

class NicoNico
  attr_accessor :flv_info

  #ref https://gist.github.com/mpppk/118a3dcf93324429fb1e
  #ref http://blog.livedoor.jp/mgpn/archives/51886270.html

  def login(mail, password)
    #ログインを試みる
    https = Net::HTTP.new('secure.nicovideo.jp', 443)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = https.start{|https|
      https.post('/secure/login?site=niconico', "mail=#{mail}&password=#{password}")
    }

    #set-cookieには複数のcookieが設定されている。
    #user_sessionがdeletedでない最初のcookieを探す。
    user_session = nil
    nicosid = nil
    response.get_fields('set-cookie').each {|cookie|
      cookie.split('; ').each {|param|
        pair = param.split('=')
        if pair[0] == 'user_session' then
          user_session = pair[1] if pair[1] != 'deleted'
          break
        end
      }
      break unless user_session.nil?
    }

    response.get_fields('set-cookie').each {|cookie|
      cookie.split('; ').each {|param|
        pair = param.split('=')
        if pair[0] == 'nicosid' then
          nicosid = pair[1]
          break
        end
      }
      break unless nicosid.nil?
    }
    @nicosid = nicosid
    @session_id = user_session
    p @nicosid
    p user_session
    return user_session
  end

  # getflvから動画情報取得
  def get_flvinfo(movie_id)

    #http://jk.nicovideo.jp/api/getflv?v=

    host = 'jk.nicovideo.jp'
    path = "/api/getflv?v=#{movie_id}"

    response = Net::HTTP.new(host).start { |http|
      request = Net::HTTP::Get.new(path)
      request['cookie'] = "nicosid=#{@nicosid};user_session=#{@session_id};"
      http.request(request)
    }

    flv_info = {}
    response.body.split('&').each do |st|
      stt = st.split('=')
      flv_info[stt[0].to_sym] = URI.unescape(stt[1])
    end

    @flv_info = flv_info
    #puts @flv_info[:ms]
    #puts @flv_info[:ms_port]
    #puts @flv_info[:thread_id]
=begin
      {:done=>"true",
       :thread_id=>"1448218801",
       :ms=>"202.248.110.179",
       :ms_port=>"2526",
       :http_port=>"8081",
       :channel_no=>"1",
       :channel_name=>"NHK 総合",
       :genre_id=>"1",
       :twitter_enabled=>"1",
       :vip_follower_disabled=>"0",
       :twitter_vip_mode_count=>"10000",
       :twitter_hashtag=>"#NHK",
       :twitter_api_url=>"http://jk.nicovideo.jp/api/v2/",
       :base_time=>"1448218801",
       :open_time=>"1448218801", 2015年 11月23日 月曜日 04時00分01秒 JST
       :start_time=>"1448218801",
       :end_time=>"1448267811", 2015年 11月23日 月曜日 17時36分51秒 JST
       :user_id=>"", 数値
       :is_premium=>"1",
       :nickname=>"" 実際の名前
      }
=end
  end

  # getplayerstatusから動画情報取得
  # XML処理
  # http://k-shogo.github.io/article/2013/09/03/ruby-xml/
  def getplayerstatus(movie_id)
    host = 'live.nicovideo.jp'
    path = "/api/getplayerstatus/#{movie_id}"

    response = Net::HTTP.new(host).start { |http|
      request = Net::HTTP::Get.new(path)
      request['cookie'] = "nicosid=#{@nicosid};user_session=#{@session_id};"
      http.request(request)
    }

    doc = REXML::Document.new(response.body.strip)
    Hash.from_xml(doc.to_s)
  end

  def get_waybackkey(thread_id)
    #http://watch.live.nicovideo.jp/api/getwaybackkey
    host = 'watch.live.nicovideo.jp'
    path = "/api/getwaybackkey?thread=#{thread_id}"
    p path
    response = Net::HTTP.new(host).start { |http|
      request = Net::HTTP::Get.new(path)
      request['cookie'] = "user_session=#{@session_id}"
      http.request(request)
    }
    p response.body
    @wayback_key = response.body.split('=')[1]
  end
end

