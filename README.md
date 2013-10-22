HLS Dumper
=======

Usage:
> ruby hlsdumper.rb playlist_URL result_dir_name

Example 1:
> ruby hlsdumper.rb http://127.0.0.1:1935/vod/sample.mp4/playlist.m3u8 output

In "output" dir there will be the playlist and all of its chunks downloaded.

Example 2 for various bitrates:
> ruby hlsdumper.rb http://127.0.0.1:1935/vod/smil:bigbuckbunny.smil/playlist.m3u8 output

In "output" dir there will be the stream, each beatrate will be stored separately with its own playlist and all the chunks.

At the moment it works for VOD content only. Let us know if there's a need for live stream dumping, it's possible to implement that as well.


This script is released under GPLv3 license: http://www.gnu.org/licenses/gpl.html


Please also take a look at our Nimble HTTP Streamer: https://wmspanel.com/nimble

It's the HTTP streaming server capable of MP4 transmuxing to HLS in VOD mode as origin and re-streaming HLS as edge server.
