require 'eventmachine'

require 'rexml/document'
require 'pp'

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

  #EMによって自動的に呼び出される
  def post_init
    puts "Send Request"

    #文字列の最後にヌル文字列が必要なことに注意
    send_data_req = sprintf('<thread thread="%d" version="20061206" res_from="-10" />' + "\0", @@thread_id)

    #for debug
    puts send_data_req

    send_data send_data_req
  end

  #EMによって自動的に呼び出される
  def receive_data(data)
    puts "Received #{data.length} bytes"
    if data.start_with?('<chat')
      NicoNicoJikkyo.parse_chat(data)
    else
      #別アプローチでパース
      NicoNicoJikkyo.parse_chat_with_thread(data)
    end
    #"<chat thread=\"1448218807\" no=\"7365\" vpos=\"5353029\" date=\"1448272346\" mail=\"184\" user_id=\"shB9qSYGHbo32He0L596lP5w5NY\" anonymity=\"1\">\xE3\x81\x9B\xE3\x82\x84\xE3\x82\x8D\xE3\x81\x8B</chat>\x00"
  end
end


class NicoNicoJikkyo
  def self.parse_chat(data)
    puts data.delete("\x0")
  end

  def self.parse_chat_with_thread(data)
    puts data.delete("\x0")
  end
end

@hostname = ARGV[0]
@port = ARGV[1].to_i
@@thread_id = ARGV[2].to_i

EM.run do
  EM.connect(@hostname, @port, Connector)
end