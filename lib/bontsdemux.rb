#!ruby -Ku
#
# BonTsDemuxを扱う

require "pathname"


# tsファイルからmp4ファイル用audioを抽出. 1chか2ch.
class BonTsDemux
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
  
  def initialize ts_file
    # まずesを変更し2ファイル生成
    @audio = [0,1].collect{|es| self.class.btdcmd(ts_file, es) }
    raise("BonTsDemux : no output file : #{ts_file}") unless @audio.all?
    # 同じ結果なら後者を削除
    @audio.pop if @audio[0].binread == @audio[1].binread
  end
  attr_reader :audio
end

