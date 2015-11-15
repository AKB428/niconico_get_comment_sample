require 'json'
require 'open-uri'
require 'net/https'

#https://gist.github.com/mpppk/118a3dcf93324429fb1e
#ref http://blog.livedoor.jp/mgpn/archives/51886270.html
class NicovideoAPIWrapper
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
    @session_id = user_session
    return user_session
  end

  # getflvから動画情報取得
  def get_flv_info(movie_id)
    host = 'flapi.nicovideo.jp'
    path = "/api/getflv/#{movie_id}"

    response = Net::HTTP.new(host).start { |http|
      request = Net::HTTP::Get.new(path)
      request['cookie'] = "user_session=#{@session_id}"
      http.request(request)
    }

    flv_info = {}
    response.body.split('&').each do |st|
      stt = st.split('=')
      flv_info[stt[0].to_sym] = stt[1]
    end
    flv_info[:ms] =~ /(http%3A%2F%2Fmsg\.nicovideo\.jp%2F)(.*?)(%2Fapi%2F)/
    flv_info[:msg] = $2

    return flv_info
  end

  # 与えられた動画IDの情報を返す
  def get_movie_info(movie_id, max_num = 100)
    flv_info       = get_flv_info(movie_id)
    msg_server_url = URI.unescape( flv_info[:ms] ).gsub("/api/", "")
    thread_id      = flv_info[:thread_id]
    movie_info_url = "#{msg_server_url}/api.json/thread?version=20090904&thread=#{thread_id}&res_from=-#{max_num}"
    JSON.load( open(movie_info_url).read )
  end

  # 与えられた動画IDのコメント情報を返す
  def get_comments_info(movie_id, max_num = 100)
    movie_info =  get_movie_info(movie_id, max_num)
    comments_info = []
    movie_info.each do |v|
      p v
      comments_info << v["chat"] if v.has_key?("chat")
    end
    comments_info
  end

  # 与えられたコメント情報からコメントを抜き出す
  def extract_comments(infos)
    infos.map { |info| info["content"] }
  end

  # 与えられた動画IDからコメントを返す
  def get_comments(movie_id, max_num = 100)
    comments_info = get_comments_info(movie_id, max_num)
    extract_comments(comments_info)
  end
end

# 配列の要素一つを一行としてファイルに保存する
def save_array arr, dst_pass
  File.write(dst_pass, arr.join("\n"))
end

# main
NICO_MAIL  = ARGV[0]
NICO_PASS  = ARGV[1]
MOVIE_ID   = ARGV[2]
DST_DIR    = "comments"

Dir.mkdir(DST_DIR) unless File.exists?(DST_DIR)

nico = NicovideoAPIWrapper.new
nico.login(NICO_MAIL, NICO_PASS)
comments = nico.get_comments(MOVIE_ID, 1000)

time_st = d.strftime("%Y%m%d%H%M%S")
save_array(comments, "#{DST_DIR}/#{MOVIE_ID}_#{time_st}_comments.csv")