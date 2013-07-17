#!ruby -Ku
# 
# 字幕ファイルの整理用

require "pathname"
mydir = Pathname(__FILE__).dirname.expand_path
require(mydir + "ass")
require(mydir + "srt")


# tsファイルからsrtとassの字幕を抜き出して結合していく
class TSCaption
  # Caption2AssのPath設定
  def self.set_c2a c2a_path; @@c2a = c2a_path; end
  
  # Caption2Assの実行.
  # => [srt file path or nil(false), ass file path or nil(false)]
  def self.c2a ts_file
    ts_file = Pathname ts_file
    cmd = %Q!"#{@@c2a}" -format dual "#{ts_file}"!
    `#{cmd} 2>&1`
    return [".srt", ".ass"].collect{ |ext|
      pt = ts_file.sub_ext(ext)
      pt.file? && pt
    }
  end
  
  def initialize
    @srt, @ass = Srt.new, Ass.new
  end
  
  # 字幕追加. offsetは時間offset [s]
  def add ts_file, offset
    srtf, assf = self.class.c2a(ts_file)
    @srt.add_srt(srtf.read.toutf8, offset) if srtf
    @ass.read_ass(assf.to_s, offset) if assf
  end
  
  # out_file(Pathname)に対応するファイル名で字幕書き出し(ある場合)
  def writeout out_file
    out_file = Pathname out_file
    @srt.write(out_file.sub_ext ".srt") unless @srt.empty?
    @ass.write(out_file.sub_ext ".ass") unless @ass.empty?
  end
end


