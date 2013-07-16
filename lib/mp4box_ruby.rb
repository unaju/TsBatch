#!ruby -Ku

require "#{File.dirname(__FILE__)}/wincode"
require "time"

# Mp4boxコマンドを格納
class Mp4boxCmd
  def initialize m4b
    @cmd = %Q!"#{m4b}"!
  end
  attr_reader :cmd 
  
  def add_cmd cmd, file = nil, track = nil
    @cmd += " -#{cmd}"
    @cmd += %Q! "#{file}"! if file
    @cmd += '#' + track if track
  end
  
  def set_output path; add_cmd("new", path); end
  def add_video path; add_cmd("add", path, "video"); end
  def add_audio path
    delay = (path.to_s =~ /\s(\-?\d+)ms.aac$/) && $1
    add_cmd("add", path, "audio")
    @cmd += " -inter #{delay}" if delay
  end
  
  def exe
    puts @cmd
    win_rsys(@cmd)
  end
end

# MP4boxのコマンド生成と実行
class Mp4box
  def initialize m4b_path
    @m4b = m4b_path
  end
  
  # ファイル情報を得る
  def info file, track = nil
    win_rsys(%!"#{@m4b}" -info #{track} "#{file}"!)
  end
  
  # mp4の長さを得る. => [Float(seconds)]
  def mp4_length file
    info(file).scan(/Duration\s(\d+:\d+:\d+\.\d+)/).collect{ |mt|
      Time.parse(mt[0], Time.new(0)) - Time.new(0)
    }
  end
  
  # 動画と音声を結合するコマンドを生成
  def join_movie video, audio, out
    c = cmd
    c.set_output(out)
    c.add_video(video)
    c.add_audio(audio)
    c
  end
  
  # 動画を結合するコマンドを生成
  def join_movies out, movies
    c = cmd
    c.set_output(out)
    movies.each{ |mv| c.add_cmd("cat", mv) }
    c
  end
  
  # コマンド生成クラスのnew
  def cmd; Mp4boxCmd.new(@m4b); end
  
  
end


