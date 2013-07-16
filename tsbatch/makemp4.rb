#!ruby -Ku
# 
# 完成版mp4生成バッチ.
# エンコード後で.tsと.mp4が揃った後に実行.
# 処理対象ディレクトリのts,mp4のペアに対して再帰的に実行される.

#!ruby -Ku
require "yaml"
require "pathname"
require "kconv"

MYDIR = Pathname.new(__FILE__).dirname.expand_path
libdir = (MYDIR + "../lib").expand_path
require(libdir + "wincode")
require(libdir + "tsfilelist")
require(libdir + "caption/caption")
require(libdir + "mp4box_ruby")

# tsファイルからmp4ファイル用audioを抽出. 1chか2ch.
class MP4Audio
  # bon_ts_demuxを設定する
  def self.set_bon bon_path; @@btd = bon_path; end
  
  # bon_ts_demuxの実行コマンドを生成,実行の後にそのPathを返す
  def self.btdcmd file, es
    # 実行
    cmd = %Q!"#{@@btd}" -i "#{file}" -nogui -quit -es #{es} -encode Demux(aac) -nd -bg!
    system cmd
    
    # 出力ファイル検索. globでは全角に対応できない.
    file = Pathname file
    filedir, filename = file.dirname, file.basename(".*")
    filedir.opendir.each { |f|
      next unless (/^(.*?) (DELAY -?\d+ms\.aac)$/ =~ f.toutf8) && ($1 == filename)
      # ファイル名をesを含むものに変更
      newpath = filedir + "#{$1} es#{es} #{$2}"
      (filedir + f).rename(newpath)
      return newpath
    }
    return nil
  end
  
  def initialize mp4_file
    # まずesを変更し2ファイル生成
    @audio = [0,1].collect{|es| btdcmd(mp4_file, es) }
    raise("BonTsDemux : no output file : #{mp4_file}") unless @audio.all?
    # 同じ結果なら後者を削除
    @audio.pop if @audio[0].binread == @audio[1].binread
  end
  attr_reader :audio
end




