#!ruby -Ku
require 'test/unit'

require "pathname"
SOLDIR = (Pathname(__FILE__).dirname + '..').expand_path # solution dir
$:.unshift SOLDIR
require "lib/bontsdemux"

require "yaml"
require "kconv"

class Ts_Tester < Test::Unit::TestCase
  def setup
    BonTsDemux.set_bon(YAML.load_file(SOLDIR + "tsbatch/config.yml")[:BTD])
  end
  
  def test_bon
    testd = Pathname("e:/t")
    testd = testd + testd.opendir.find{|f| f.toutf8 !~ /^\.+$/ }
    
    p testd.to_s.toutf8 # ここでtestdが全角パスを含むようにする
    
    testd.opendir.each { |f|
      f = testd + f
      next unless f.file?
      p f
      p BonTsDemux.extract(f)
    }
  end
end
