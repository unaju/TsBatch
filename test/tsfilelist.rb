#!ruby -Ku

require 'test/unit'
require 'kconv'
require "pathname"
$:.unshift (Pathname(__FILE__).dirname + '..').expand_path.to_s
require "lib/tsfilelist"

class TSFileList_Tester < Test::Unit::TestCase
  def setup
  end
  
  def viewlist tsfiles
    tsfiles.each{|f| puts f.to_s.toutf8 }
  end
  
  
  def test_no_gop
    viewlist TSFileList.make_nogop("e:/")
    
  end
end
