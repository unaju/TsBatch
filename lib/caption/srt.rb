#!ruby -Ku

require "time"

# 字幕1つのクラス. 開始、終了時間と字幕内容を保持.
class SrtValue
  attr_accessor :bg, :ed, :cp

  def initialize bg,ed,cp
    @bg,@ed,@cp = bg,ed,cp
  end

  REG_PARSE_SRT = %r!\d+\n(\d+:\d+:\d+,\d+)\s+\S+\s+(\d+:\d+:\d+,\d+)\n(.*)!m
  # 文字列から分解. /\n\n/から区切ったものを渡す.
  def self.parse str
    (str =~ REG_PARSE_SRT) && SrtValue.new(
      *([$1, $2].collect{ |t| Time.parse(t, Time.new(0)) }), $3
    )
  end
  
  # 時間をずらしてselfを返す.
  def offsetting t
    @bg += t
    @ed += t
    self
  end

  # \n\nもついてくる
  def to_s number = 1
    "%d\n%s --> %s\n%s\n\n" % [
      number, *([@bg,@ed].collect{|t| t.strftime "%H:%M:%S,%L" }), @cp
    ]
  end
end

# 字幕ファイルを扱うクラス
class Srt < Array
  # 後尾にsrtを解析して追加
  def add_srt str_srt, offset = 0.0
    str_srt.split(/\n\n+/).each{ |base|
      #p base
      # パース失敗の場合はskip
      sv = SrtValue.parse(base)
      self << sv.offsetting(offset) if sv
    }
  end
  
  # 出力できる形式に変換
  def to_s
    (0...size).collect{|i| at(i).to_s(i+1) }.join("")
  end
  
  # 保存. UTF8,BOM付き
  def write path
    IO.write(path, "\xEF\xBB\xBF" + to_s)
  end
end


if __FILE__ == $0
  s = Srt.new
  s.add_srt IO.read("C:/_conv/kmb1/s.srt")
  puts s.to_s
end

