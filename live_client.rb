require 'json'
require 'open-uri'
require 'net/https'
require 'csv'
require './lib/niconico'
require 'pp'

#https://gist.github.com/mpppk/118a3dcf93324429fb1e
#ref http://blog.livedoor.jp/mgpn/archives/51886270.html
#ref http://needtec.exblog.jp/21547762/
#ref http://www.slideshare.net/masahiroh1/ss-24757915
#vpos 1/100 秒

class Live

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

  @hostname = info['getplayerstatus']['ms']['addr']
  @port =  info['getplayerstatus']['ms']['port']
  @thread_id = info['getplayerstatus']['ms']['thread']

  puts @hostname
  puts @port
  puts @thread_id

  time_st = Time.now.strftime("%Y%m%d-%H%M%S")
  @filename = "#{DST_DIR}/#{@thread_id}_#{time_st}_comments.tsv"
end

live_init