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
  #EMによって自動的に呼び出される
  def post_init
    puts "Send Request"

    #文字列の最後にヌル文字列が必要なことに注意
    send_data_req = sprintf('<thread thread="%s" version="20061206" res_from="-10" />' + "\0", @@thread_id)

    #for debug
    puts send_data_req

    send_data send_data_req
  end

  #EMによって自動的に呼び出される
  def receive_data(data)
    puts data
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

  #pp info

  hostname = info['getplayerstatus']['ms']['addr']
  port =  info['getplayerstatus']['ms']['port']
  thread_id = info['getplayerstatus']['ms']['thread']

  puts hostname
  puts port
  puts thread_id

  time_st = Time.now.strftime("%Y%m%d-%H%M%S")
  filename = "#{DST_DIR}/#{thread_id}_#{time_st}_comments.tsv"

  {
      :hostname => hostname,
      :port => port,
      :thread_id => thread_id,
      :filename => filename
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