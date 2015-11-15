require 'json'
require 'open-uri'
require 'net/https'

#https://gist.github.com/mpppk/118a3dcf93324429fb1e
#ref http://blog.livedoor.jp/mgpn/archives/51886270.html

class NicovideoAPIWrapper

  COMMENT_MAX_NUM = 1000
  @flv_info = nil

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

  def get_waybackkey(thread_id)
    host = 'flapi.nicovideo.jp'
    path = "/api/getwaybackkey?thread=#{thread_id}"
    p path
    response = Net::HTTP.new(host).start { |http|
      request = Net::HTTP::Get.new(path)
      request['cookie'] = "user_session=#{@session_id}"
      http.request(request)
    }
    p response
    @wayback_key = response.body.split('=')[1]
  end


  # 与えられた動画IDの情報を返す
  def get_movie_info(movie_id)
    @flv_info       = get_flv_info(movie_id)
    p @flv_info
    get_waybackkey(@flv_info[:thread_id])
    p @wayback_key
    #exit


    #p flv_info
    msg_server_url = URI.unescape( @flv_info[:ms] ).gsub("/api/", "")
    thread_id      = @flv_info[:thread_id]
    movie_info_url = "#{msg_server_url}/api.json/thread?version=20090904&thread=#{thread_id}&res_from=-#{COMMENT_MAX_NUM}"
    JSON.load( open(movie_info_url).read )
  end

  # 与えられた動画IDの情報を返す
  def get_movie_info_with_when(movie_id, when_time)
    #p flv_info
    msg_server_url = URI.unescape( @flv_info[:ms] ).gsub("/api/", "")
    thread_id      = @flv_info[:thread_id]

    host_info = msg_server_url.split('/')
    p host_info
    host = host_info[2]
    root_path = host_info[3]
    path = "/#{root_path}/api.json/thread?version=20090904&thread=#{thread_id}&res_from=-#{COMMENT_MAX_NUM}&when=#{when_time}&waybackkey=#{@wayback_key}"

    p path
    response = Net::HTTP.new(host).start { |http|
      request = Net::HTTP::Get.new(path)
      request['cookie'] = "user_session=#{@session_id};nicosid=#{@nicosid}"
      http.request(request)
    }

    JSON.load(response.body)
  end


  # 与えられた動画IDのコメント情報を返す
  def get_comments_info(movie_id)
    movie_info =  get_movie_info(movie_id)

    comment_num = movie_info[0]['thread']['last_res']
    p comment_num
    loop_num = comment_num / COMMENT_MAX_NUM
    p loop_num
    p (comment_num % COMMENT_MAX_NUM)
    loop_num = loop_num + 1 if (comment_num % COMMENT_MAX_NUM) > 0
    p loop_num

    comments_info = []

    (1..loop_num).each do |num|
      next_when = nil
      puts 'loop=' + num.to_s + ' length=' + movie_info.length.to_s
      movie_info.each do |v|
        #p v
        if next_when.nil? && v.has_key?("chat")
          next_when = v["chat"]['date']
        end

        comments_info << v["chat"] if v.has_key?("chat")
      end

      p next_when
      movie_info = get_movie_info_with_when(movie_id, next_when)
    end

    comments_info
  end

  # 与えられたコメント情報からコメントを抜き出す
  def extract_comments(infos)
    infos.map { |info| info["content"] }
  end

  # 与えられた動画IDからコメントを返す
  def get_comments(movie_id)
    comments_info = get_comments_info(movie_id)
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
comments = nico.get_comments(MOVIE_ID)

time_st = Time.now.strftime("%Y%m%d-%H%M%S")
save_array(comments, "#{DST_DIR}/#{MOVIE_ID}_#{time_st}_comments.csv")