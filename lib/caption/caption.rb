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
    system %Q!"#{@@c2a}" -format dual "#{ts_file}"!
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
    srtf, assf = c2a(ts_file)
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






=begin
# 字幕のoffset時間を取得. => [0, t1, t1+t2, ...]. 最後の要素は別にいらない.
def get_offset mp4s
	offset, result = 0.0, [0.0]
  mp4s.each{ |mp4| result << (offset += Mp4box.mp4_length(mp4)[0]) }
  result
end


# 字幕ファイルがあるなら結合し => [srt, ass]. 無いならそれがnil
def get_caption mp4s, srts, asss, cpo
  srt = (mp4s.size == srts.size) ? Srt.new : nil
	ass = (mp4s.size == asss.size) ? Ass.new : nil
  
  srts.size.times{|i| srt.add_srt(srts[i].read.toutf8, cpo[i]) } if(srt)
  asss.size.times{|i| ass.read_ass(asss[i].to_s, cpo[i]) } if(ass)
  
  [srt, ass]
end





# srtが十分あるなら結合してそのパスを返す. 無いならnil.
def srt_join mp4s, srts
  return nil if srts.empty? || (mp4s.size > srts.size)
  
  # srtをoffsetしながら追加
  srt_v, offset = Srt.new, 0.0
  mp4s.each_with_index { |mp4,idx|
    srt_v.add_srt(srts[idx].read.toutf8, offset)
    offset += Mp4box.mp4_seconds(mp4)
  }
  
  # srt書き出し
  IO.write(TEMP_FILE[:srt].to_s, srt_v.to_s)
  TEMP_FILE[:srt]
end
=end
