#
# provided by wmspanel.com team
# Author: Alex Pokotilo
# Contact: support@wmspanel.com
#
require 'net/http'

def parseURL(url)
  domain_port = ((url.split /\//)[2]).split /:/ # get domain and port
  port = domain_port[1] ? domain_port[1].to_i : 80 # get port or use 80 by default
  domain = domain_port[0]
  return domain, port
end

def httpChecks(request)
  raise "Server returned code #{request.code}" unless request.code == "200"

  raise "Wrong Content-type. We support only content-type=application/vnd.apple.mpegurl but #{request.header['content-type']} returned" unless
      (request.header['content-type'] == 'application/vnd.apple.mpegurl' || request.header['content-type'] == 'video/MP2T')
end

def processPlaylist(http, url, output_dir)
  Dir.mkdir output_dir unless Dir.exist? output_dir

  url = url.split /\//
  url.slice! 0..2
  url = "/#{url.join '/'}"

  request = http.get url

  httpChecks request
  lines =  request.body.split(/\n/)
  raise "wrong playlist format" unless lines[0] == "#EXTM3U"

  File.open "#{output_dir}#{File::SEPARATOR}playlist.m3u8", 'w' do |file|
    lines.each { |line| file.puts line} # TODO: substitute to one from command line
  end
  lines.slice! 0  # lets remove #EXTM3U

  threads = []

  read_playlist = false
  load_ts_chunk = false

  base_url = url[0, url.index(/\/[a-z]*.m3u8/)]
  chunk_count = 0
  dir_name = nil
  dir_count = 0

  lines.each {|line|
    if read_playlist
      dir = dir_name
      newthread_url = line
      threads << Thread.new{loadStreams(newthread_url, "#{output_dir}#{File::SEPARATOR}#{dir}")}
      read_playlist = false
      dir_name = nil
      next
    elsif load_ts_chunk
      chunk = http.get "#{base_url}/#{line}"
      httpChecks chunk
      chunk_count+= 1
      File.open "#{output_dir}#{File::SEPARATOR}media_#{chunk_count}.ts", 'wb' do |file|
        file.write chunk.body
      end
      load_ts_chunk = false
      next
    end

    if line.start_with? "#EXT-X-STREAM-INF:"
      line.slice!('#EXT-X-STREAM-INF:')
      params = line.split /,/
      bandwidth = params.select {|v| v =~ /BANDWIDTH=[0-9]*/}
      bandwidth = bandwidth ? bandwidth[0].split(/=/) : nil
      dir_name = bandwidth.size == 2 ? bandwidth[1] : dir_count.to_s
      dir_count+= 1
      read_playlist = true
      next
    end

    if line.start_with? "#EXTINF:"
      load_ts_chunk = true
      next
    end
  }

  threads.each {|thread| thread.join}
end

def loadStreams(url, output_dir)
  domain, port = parseURL(url)
  Net::HTTP.start(domain, port) do |http|
    processPlaylist(http, url, output_dir)
  end
end

p "wrong argument count. please " unless ARGV.length == 2


loadStreams(ARGV[0], ARGV[1])