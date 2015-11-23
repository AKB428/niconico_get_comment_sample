require 'net/https'
require 'eventmachine'

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
    p data
  end
end


@hostname = ARGV[0]
@port = ARGV[1].to_i
@@thread_id = ARGV[2].to_i

EM.run do
  EM.connect(@hostname, @port, Connector)
end