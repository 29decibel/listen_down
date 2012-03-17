# take an arg
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'uri'
require 'iconv'
require 'fileutils'

#QUERY_URL = "http://mp3.sogou.com/music.so?query=beyond&class=1&pf=&w=02009900&st=&ac=1&sourcetype=sugg&w=02009900&dr=1&_asf=mp3.sogou.com&_ast=1331969881"
#QUERY_URL = "http://mp3.sogou.com/music.so?query=%CD%F4%B7%E5&class=1&st=&ac=&pf=mp3&_asf=mp3.sogou.com&_ast=1331969922&p=&w=&w=02009900"
SERVER_HOST = "http://mp3.sogou.com"

def songs_of_query(query)
  safe_query = URI.escape(Iconv.new('gb2312', 'utf-8').iconv(query))
  puts "begin search #{query}..."
  search_url = "http://mp3.sogou.com/music.so?query=#{safe_query}&class=1&st=&ac=&pf=mp3&_asf=mp3.sogou.com&_ast=1331969922&p=&w=&w=02009900"
  search_doc = Nokogiri::HTML(open(search_url))
  songs = []
  search_doc.css("#songlist tr").each do |song_info|
    raw_name = song_info.at_css(".songname a")
    next unless raw_name
    name = raw_name.content
    raw_address = song_info.at_css("a.link")
    next unless raw_address
    link_matches = raw_address['onclick'].match /window.open\('(.*?)'/
    next unless download_page = link_matches[1]
    songs << {:name=>name,:link=>song_address(download_page)}
  end
  songs
end

def song_address(download_page)
  dp = Nokogiri::HTML(open("#{SERVER_HOST}#{download_page}"))
  dp.css('table.linkbox a').first['href']
end

def download(name,link)
  prepare_dir
  File.open(local_path(name),'w') do |f|
    puts "downloading #{name} from #{link} ..."
    f.puts open(link).read
  end
end

def prepare_dir
  FileUtils.mkdir('musics') unless File.exist?('musics')
end

def local_path(name)
  "./musics/#{name}.mp3"
end

# downlaod songs
songs = songs_of_query ARGV[0]
puts "find #{songs.length} songs, begin downlaoding them..."
# create 5 threads
workers = []
while songs.count>0
  current_songs = songs[0..4]
  worker = Thread.new(current_songs) do |my_songs|
    my_songs.each do |song_info|
      download(song_info[:name],song_info[:link])
    end
  end
  workers << worker
  songs = songs - current_songs
end
puts "create workers #{workers.count}"
workers.each {|w| w.join }

