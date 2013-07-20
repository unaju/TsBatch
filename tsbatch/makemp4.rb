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
#require(libdir + "wincode")
require(libdir + "tsfilelist")
require(libdir + "caption/caption")
require(libdir + "mp4box_ruby")
require(libdir + "bontsdemux")



# Progress表示用. begin_messageを表示してからyield結果 + 処理時間を表示
def view_progress begin_message
	print begin_message
  t = Time.now
  print yield
  puts " (%.2fs)" % (Time.now() - t)
end



# joinするjob. 1 file / 1 job instance
class MP4JoinJob
  # テンポラリディレクトリを設定
  def self.set_temp temp; @@tempdir = temp; end
  
  # 引数はPathname限定
  def initialize dest_dir, out_rel_path
    @o_relp, @dest_d, @dest_f = out_rel_path, dest_dir, (dest_dir + out_rel_path)
    @input_files = [] # [ts file path]
  end
  attr_reader :o_relp, :input_files
  
  # ファイル追加
  def add tsfile, index; @input_files[index] = tsfile; end
  # ファイル追加終了時にnilを削除
  def addition_finish; @input_files.compact! end
  
  # job実行.
  def execjob
    @dest_d.mkpath # 保存先準備
    (@input_files.size > 2) ? execjob_multi_movie : execjob_single_movie
  end
  
  # 1
  def execjob_single_movie
    tsf = @input_files[0]
    
    # 音声をtsから抽出
    audios = nil
    view_progress("extract audio ... ") {
      audios = BonTsDemux.extract(tsf)
      "#{audios.size} audios"
    }
    # 音声を無音mp4(エンコード結果)と結合
    view_progress("join audio and video ... ") {
      MP4Box.cmd_join_av(
        @dest_f.sub_ext(".mp4"), tsf.sub_ext(".mp4"), *audios
      ).exe_cmd
      "complete"
    }
    # 字幕抽出
    view_progress("extract caption ... ") {
      caption = TSCaption.new
      caption.add(tsf, 0.0)
      caption.writeout(@dest_f)
      "complete"
    }
  end
  
  # 複数のファイルを結合する場合
  def execjob_multi_movie
    # phase1. ファイルごとに必要な前処理をする
    offset = 0.0
    caption = TSCaption.new
    temp_mp4s = [] # tempに書き出されたmp4のPath
    
    @input_files.each_with_index { |tsf, idx|
      puts "phase1 : #{tsf.basename} (#{idx + 1}/#{@input_files.size})"
      mp4f = tsf.sub_ext(".mp4")
      
      # 音声をtsから抽出
      audios = nil
      view_progress("extract audio ... ") {
        audios = BonTsDemux.extract(tsf)
        "#{audios.size} audios"
      }
      
      # 音声を無音mp4(エンコード結果)と結合
      temp_mp4 = @@tempdir + "mp4jointemp-#{idx}.mp4"
      temp_mp4s << temp_mp4
      view_progress("join audio and video ... ") {
        MP4Box.cmd_join_av(temp_mp4, mp4f, *audios).exe_cmd
        "complete"
      }
      
      # 字幕抽出
      view_progress("extract caption ... ") {
        caption.add(tsf, offset)
        offset += MP4Box.mp4_length(mp4f).first
        "complete"
      }
    }
    
    # phase2. 動画を結合し字幕を書き出す
    view_progress("phase2 : join mp4s ... ") {
      MP4Box.cmd_join_movies(@dest_f.sub_ext(".mp4"), temp_mp4s).exe_cmd
      caption.writeout(@dest_f)
      "complete"
    }
    
    # 書き出したtempを削除
    view_progress("remove temporary files : ") {
      temp_mp4s.each{|f| f.delete }
      "complete"
    }
  end
  
  
  # ディレクトリ以下のjobを生成 => Array
  def self.makejob src, dest
    src, dest = [src, dest].collect{ |v| Pathname.new v }
    
    # {out_relative_path => job}
    jobs = Hash.new{ |h,k| h[k] = self.new(dest, k) }
    
    # エンコード済みtsファイルを列挙してまとめる
    TSFileList.make_encorded(src).each{ |tsf| # input ts file
      case tsf.basename.to_s.toutf8
      when /^(\d+)-(\d+)\.ts$/i # <index1>-<index2>.tsの形式
        jobs[(tsf.dirname.relative_path_from(src) + $1)].add(tsf, $2.to_i)
      when /^(\d+)\.ts$/i # <index1>.tsの形式
        jobs[(tsf.dirname.relative_path_from(src))].add(tsf, $1.to_i)
      end
    }
    
    jobs.each{ |k,j| j.addition_finish }
    return jobs.values
  end
end


def main
  # 設定読み込み
  conf = YAML.load_file(MYDIR + "config.yml")
  BonTsDemux.set_bon(conf[:BTD])
  TSCaption.set_c2a(conf[:C2A])
  MP4Box.set_m4b(conf[:M4B])
  MP4JoinJob.set_temp(wpath conf[:temp])
  
  dest = wpath conf[:dest]
  
  # 対象directory取得
  print "dir >"
  dir = STDIN.gets.to_s.chomp.toutf8
  return if dir.empty?

  # 変換ファイル取得
  jobs = MP4JoinJob.makejob(wpath(dir), dest)

  # 確認
  jobs.each { |j|
    i = j.input_files.collect{|f| f.basename(".*")}.join(", ")
    puts "[#{i}] => #{j.o_relp}"
  }
  print "y/n >"
  return unless STDIN.gets.to_s.chomp.downcase == "y"

  # 実行
  jobs.each{ |j|
    puts "-"*60
    view_progress("job : #{j.o_relp}\n") {
      j.execjob
      "job complete"
    }
  }
end
main if __FILE__ == $0



