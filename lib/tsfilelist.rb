#!ruby -Ku
#
# 処理対象ファイルリストを生成する

require "pathname"
require "kconv"

# 処理対象ファイルのリスト
class TSFileList < Array
  # 条件BLOCKに一致するtsを再帰的に追加
  def adddir dir, &tschecker
    dir = Pathname(dir)
    dir.opendir.each{ |f|
      f2 = dir + f
      if f2.file? && (f2.extname == ".ts")
        push(f2) if tschecker.call(f2)
      elsif f2.directory? && (f.toutf8 !~ /^\.+$/)
        adddir(f2, &tschecker)
      end
    }
    self
  rescue Errno::EACCES
    # permissionが無いdirectoryをopendirをopenしようとした時の例外. 無視.
  end
  
  # 条件に一致するtsを再帰的に追加したリストを生成
  def self.make4dir dir, &tschecker
    return self.new.adddir(dir, &tschecker)
  end
  
  # MMEで生成されるglファイルが無いtsファイルのリストを再帰的に生成
  def self.make_nogop dir
    return self.make4dir(dir){|f| ! f.sub_ext(".gl").file? }
  end
  
  # mp4エンコード済みのtsファイルのリストを再帰的に生成
  def self.make_encorded dir
    return self.make4dir(dir){|f| f.sub_ext(".mp4").file? }
  end
  
end

# windowsのpathからPathname作成. \を/にしたりする. おまけ.
def wpath path
  return Pathname.new path.sub(/^\"(.+)\"$/, "\\1").gsub('\\',"/")
end

