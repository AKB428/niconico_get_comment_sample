require 'eventmachine'
require 'csv'
require './lib/niconico'

=begin

ニコニコ実況のコメントは認証が不要
チャンネルによってIP、PORTが異なる
IP/PORT/Thread_IDを取得するには認証が必要
チャンネルは関東TV局+BS＋ラジオ

bundle exec ruby jikkyo_client.rb [ServerIP] [Port] [Thread_id]
bundle exec ruby jikkyo_client.rb 202.248.110.141 2526 1448218807

=end

#eventmatchine
#http://keijinsonyaban.blogspot.jp/2010/12/eventmachine.html

#ニコニコ実況のAPIについて
#http://sekki.org/wordpress/?p=25
#http://dev.activebasic.com/egtra/2010/03/03/210/

class Connector < EM::Connection

  #コメントが一定数たまったら保存する数
  MAX = 100

  #EMによって自動的に呼び出される
  def post_init

    @counter = 0
    @comment_data = []

    puts "Send Request"

    #文字列の最後にヌル文字列が必要なことに注意
    send_data_req = sprintf('<thread thread="%d" version="20061206" res_from="-10" />' + "\0", @@thread_id)

    #for debug
    puts send_data_req

    send_data send_data_req
  end

  #EMによって自動的に呼び出される
  def receive_data(data)
    @counter = @counter + 1
    puts "Received #{data.length} bytes"
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

nico = NicoNico.new
nico.login(NICO_MAIL, NICO_PASS)
nico.get_flvinfo(MOVIE_ID)

hostname = nico.flv_info[:ms]
port =  nico.flv_info[:ms_port]
@@thread_id =  nico.flv_info[:thread_id]

DST_DIR    = 'comments'
Dir.mkdir(DST_DIR) unless File.exists?(DST_DIR)
time_st = Time.now.strftime("%Y%m%d-%H%M%S")
@@filename = "#{DST_DIR}/#{@@thread_id}_#{time_st}_comments.tsv"

EM.run do
  EM.connect(hostname, port, Connector)
end