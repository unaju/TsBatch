#!ruby -Ku

require "time"
#require "csv"

# 字幕とHeadを保持
class Ass
  ASS_COLMNS = 'Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text'
  
  def initialize
    @head, @val = "", []
  end
  
  # 列をパース. 必要な時間の所だけ抜き出す. => [String,Time,Time,String]
  def self.parse_line line, offset = 0.0
    line.match /^([^,]+,)([^,]+),([^,]+)(,.*?)$/
    tot = Proc.new{ |s| Time.parse(s, Time.new(0)) + offset }
    [ $1, tot.call($2), tot.call($3), $4 ]
  end
  
  # 設定と字幕をセット. 字幕は追加. 設定は上書き.
  def set_ass string, offset = 0.0
    # Header前と後に分ける. [Events]の次の行までHeader
    e = string.match(/^\[Events\]\n.*\n/).end(0)
    @head = string[0,e]
    string[e...(string.size)].each_line{ |l| @val << Ass.parse_line(l, offset) }
  end
  
  # ファイルからset_ass
  def read_ass path, offset = 0.0
    open(path, 'r:BOM|UTF-8'){ |f| set_ass(f.read, offset) }
  end
  attr :head, :val
  
  # ass用の時間形式(String)に
  def Ass.asstime t
    "%d:%02d:%02d.%02d" % [ t.hour, t.min, t.sec, t.usec()/10000]
  end
  
  # 空かどうか
  def empty?
    @val.empty?
  end
  
  # stringにする
  def to_s
    @head + @val.collect{ |s1,t1,t2,s2|
      s1 + Ass.asstime(t1) + "," + Ass.asstime(t2) + s2
    }.join("\n")
  end

  # 保存. UTF8,BOM付き
  def write path
    IO.write(path, "\xEF\xBB\xBF" + to_s)
  end
  
end


if __FILE__ == $0
  a = Ass.new 
  a.read_ass "asssample.ass"
  puts a.to_s
end


