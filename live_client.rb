require 'json'
require 'open-uri'
require 'net/https'
require 'csv'
require './lib/niconico'
require 'pp'
require 'eventmachine'

#https://gist.github.com/mpppk/118a3dcf93324429fb1e
#ref http://blog.livedoor.jp/mgpn/archives/51886270.html
#ref http://needtec.exblog.jp/21547762/
#ref http://www.slideshare.net/masahiroh1/ss-24757915
#vpos 1/100 秒

class LiveConnector < EM::Connection
  attr_accessor :thread_id, :filename
  #コメントが一定数たまったら保存する数
  MAX = 100

  #EMによって自動的に呼び出される
  def post_init

    @counter = 0
    @comment_data = []

    puts "Send Request"

    #文字列の最後にヌル文字列が必要なことに注意
    send_data_req = sprintf('<thread thread="%s" version="20061206" res_from="-10" />' + "\0", @@thread_id)

    #for debug
    puts send_data_req

    send_data send_data_req
  end

  #EMによって自動的に呼び出される
  def receive_data(data)
    @counter = @counter + 1
    #puts "Received #{data.length} bytes"

    if data.start_with?('<leave_thread')
      #TODO 朝４時近辺に切断される
      EM.stop
    end

    if data.start_with?('<chat')
      @comment_data.push(NicoNicoJikkyo.parse_chat(data))
    else
      #別アプローチでパース
      NicoNicoJikkyo.parse_chat_with_thread(data)
    end
    #"<chat thread=\"1448218807\" no=\"7365\" vpos=\"5353029\" date=\"1448272346\" mail=\"184\" user_id=\"shB9qSYGHbo32He0L596lP5w5NY\" anonymity=\"1\">\xE3\x81\x9B\xE3\x82\x84\xE3\x82\x8D\xE3\x81\x8B</chat>\x00"

    if @counter == MAX
      NicoNicoJikkyo.save_array(NicoNicoJikkyo.extract_comments(@comment_data), @@filename)
      @counter = 0
      @comment_data = []
    end
  end


end

class NicoNicoJikkyo
  def self.parse_chat(data)
    r = {}
    data.scan(/\w+="\w+/).each do |x|
      #p x
      unit = x.split('="')
      r[unit[0]] = unit[1]
    end
    /<chat.+>(.+)<\/chat>/ =~ data
    r['content'] = $1
    print r['no']
    print "\t"
    print r['vpos']
    print "\t"
    puts $1
    r
  end

  def self.parse_chat_with_thread(data)
    puts data.delete("\x0")
  end

  # 与えられたコメント情報からコメントを抜き出す
  def self.extract_comments(infos)
    infos.map { |v|

      #配列の配列を作成
      record = []
      #Full column
      record[0] = v.has_key?("thread") ? v["thread"] : ''
      record[1] = v.has_key?("no") ? v["no"] : ''
      record[2] = v.has_key?("vpos") ? v["vpos"] : ''
      record[3] = v.has_key?("date") ? v["date"]  : ''
      record[4] = v.has_key?("mail") ? v["mail"]  : ''
      record[5] = v.has_key?("user_id") ? v["user_id"] : ''
      record[6] = v.has_key?("premium") ? v["premium"]  : ''
      record[7] = v.has_key?("anonymity") ? v["anonymity"] : ''
      record[8] = v.has_key?("leaf") ? v["leaf"] : '' #実況にはなさそう
      record[9] = v.has_key?("fork") ? v["fork"] : '' #実況にはなさそう
      record[10] = v.has_key?("deleted") ? v["deleted"] : '' #実況にはなさそう
      record[11] = v.has_key?("content") ? v["content"]  : ''
      record
    }
  end

  # 配列の要素一つを一行としてファイルに保存する
  def self.save_array(arr, dst_pass)

    CSV.open(dst_pass, 'a', col_sep: "\t") do |tsv|
      arr.each do |record|
        tsv << record
      end
    end
  end
end

# main
NICO_MAIL  = ARGV[0]
NICO_PASS  = ARGV[1]
MOVIE_ID   = ARGV[2]

DST_DIR    = 'comments'
Dir.mkdir(DST_DIR) unless File.exists?(DST_DIR)

def live_init
  nico = NicoNico.new
  nico.login(NICO_MAIL, NICO_PASS)
  info = nico.getplayerstatus(MOVIE_ID)

  pp info

  hostname = info['getplayerstatus']['ms']['addr']
  port =  info['getplayerstatus']['ms']['port']
  thread_id = info['getplayerstatus']['ms']['thread']

  puts hostname
  puts port
  puts thread_id

  time_st = Time.now.strftime("%Y%m%d-%H%M%S")
  @@filename = "#{DST_DIR}/#{thread_id}_#{time_st}_comments.tsv"

  {
      :hostname => hostname,
      :port => port,
      :thread_id => thread_id,
      :filename => @@filename
  }
end

EM.run do
  init_data = live_init
  @@thread_id =  init_data[:thread_id]
  EM.connect(init_data[:hostname], init_data[:port], LiveConnector) do |conn|
    conn.thread_id = init_data[:thread_id]
    conn.filename = init_data[:filename]
  end
end