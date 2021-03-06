#!ruby -Ku
#
# BonTsDemuxを扱う

require "pathname"
mydir = Pathname(__FILE__).dirname.expand_path
require(mydir + "ts_analyzer")


# tsファイルからmp4ファイル用audioを抽出. 1chか2ch. インスタンスは作らない.
class BonTsDemux
  # bon_ts_demuxを設定する
  def self.set_bon bon_path; @@btd = bon_path; end
  
  # bon_ts_demuxの実行コマンドを生成,実行の後にそのPathを返す
  def self.btdcmd file, es = nil, srv = nil
    filedir, filename = file.dirname, file.basename(".*").to_s
    
    # 実行
    cmd = %Q!"%s" -i "%s" %s-nogui -quit %s-encode Demux(aac) -nd -bg! % [
      @@btd, file, (srv && "-srv #{srv} "), (es && "-es #{es} ")
    ]
    `#{cmd} 2>&1`
    
    # 出力ファイル検索. globでは全角に対応できない.
    filedir.opendir.each { |f|
      next unless (/^(.*?) (DELAY -?\d+ms\.aac)$/i =~ f.toutf8) && ($1 == filename)
      # ファイル名をesを含むものに変更
      newpath = filedir + "#{$1} es#{es} #{$2}"
      (filedir + f).rename(newpath)
      return newpath
    }
    return nil
  end
  
  # => [audios]
  def self.extract ts_file
    ts_file = Pathname(ts_file)
    
    # 既に出力ファイルが生成されているか探索し存在する場合はそちらを返す
    dirname, filename = ts_file.dirname, ts_file.basename(".*").to_s
    o = dirname.opendir.find_all { |f|
      (/^(.*?) es\d+ DELAY -?\d+ms\.aac$/i =~ f.toutf8) && ($1 == filename)
    }
    return o.collect{|f| dirname + f} unless o.empty?
    
    # サービスID抽出
    sid = TSAnalyzer.service_id(ts_file.to_s)
    sid = sid && sid[0]
    
    # まずesを変更し2ファイル生成
    audios = [0,1].collect{|es| self.btdcmd(ts_file, es, sid) }
    raise("BonTsDemux : no output file : #{ts_file}") unless audios.all?
    
    # 同じ結果なら後者を削除
    audios.pop.delete { |unusedlocal|  } if audios[0].binread == audios[1].binread
    return audios
  end
end

