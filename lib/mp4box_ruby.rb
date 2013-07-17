#!ruby -Ku

mydir = File.expand_path File.dirname(__FILE__)
require File.join(mydir, "wincode")
require "time"


# MP4Boxの操作コマンドの管理. インスタンスはコマンドを格納
class MP4Box
  # mp4boxの指定
  def self.set_m4b mp4box_path; @@m4b = mp4box_path; end
  
  # mp4の長さを得る. => [Float(seconds)]
  def self.mp4_length file
    info(file).scan(/Duration\s(\d+:\d+:\d+\.\d+)/).collect{ |mt|
      Time.parse(mt[0], Time.new(0)) - Time.new(0)
    }
  end
  
  # ファイル情報を得る
  def self.info file, track = nil
    self.new(%!"#{@@m4b}" -info #{track} "#{file}"!).exe_cmd
  end
  
  
  # 特定の用途に対応するコマンドを生成するクラスメソッド ----
  
  
  # 音声と動画を結合するコマンドのインスタンスを生成
  def self.cmd_join_av out, video, *audios
    r = self.new
    r.set_output(out)
    r.add_video(video)
    audios.each{|a| r.add_audio(a) }
    r
  end
  
  # 動画を結合するコマンドを生成
  def self.cmd_join_movies out, movies
    r = self.new
    r.set_output(out)
    movies.each{ |mv| r.add_cmd("cat", mv) }
    r
  end
  
  
  # ここから下がインスタンスメソッド ----------------------
   
  
  def initialize opt = nil
    @cmd = %Q!"#{@@m4b}"#{opt}!
  end
  attr_reader :cmd 
  
  def add_cmd cmd, file = nil, track = nil
    @cmd += " -#{cmd}"
    @cmd += %Q! "#{file}"! if file
    @cmd += '#' + track if track
    self
  end
  
  def set_output path; add_cmd("new", path); end
  def add_video path; add_cmd("add", path, "video"); end
  def add_audio path
    delay = (path.to_s =~ /\s(\-?\d+)ms.aac$/) && $1
    add_cmd("add", path, "audio")
    @cmd += " -inter #{delay}" if delay
    self
  end
  
  def exe_cmd
    puts "\n#{@cmd}".toutf8
    win_rsys(@cmd)
  end
end





