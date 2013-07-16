#!ruby -Ku
# 
# tsファイル関連. 結局service idが不要になったためこれも不要に

class TSFile
  PACKET_SIZE = 188
  
  def set_packet ts_file, offset, length
    @bin = IO.binread(ts_file, PACKET_SIZE*length, PACKET_SIZE*offset)
  end
  
  # @binに読み込んだパケットごとにyield
  def each_packet
    offset = 0
    while @bin.size > offset + PACKET_SIZE
      yield @bin[offset, PACKET_SIZE]
      offset += PACKET_SIZE
    end
  end
  
  # 特定のPIDのパケットのみyield
  def each_pid pid
    each_packet{ |packet|
      # PID取得
      head, rest = packet.unpack "cn"
      pkt_pid = ((rest << 3) & 0xFFFF) >> 3
      # yield
      yield packet if (head == 0x47) && (pkt_pid == pid)
    }
  end
  
  # service idの取得
  def service_id
    each_pid(0) { |packet|
      r, offset = [], 0xF # offsetはとりあえず0xFから
      while true # 4Byte Splite Loop
        hd, _q, sid = packet[offset, 4].unpack "Ccn" # _qは何か. 捨てる.
        return r if hd == 0xFF # 終わりはヘッダが0xFF
        r << sid
        offset += 4
      end
    }
    return nil
  end
  
  # service idの取得(fileから)
  def self.service_id ts_file
    tsf = self.new
    tsf.set_packet(ts_file, 0, 4096)
    return tsf.service_id
  end
end