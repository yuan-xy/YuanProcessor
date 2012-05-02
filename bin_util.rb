class BinUtil
  
  attr_accessor :bin, :symLabel, :symExternLabel, :symVar, :symSegment, :uses
  
  def initialize
    @bin = []
    @symLabel = {}
    @symExternLable = {}
    @symVar = {}
    @symSegment = {}
    @uses = {}
  end
  
  def load(file)
    load_obj file
    load_symbol_table file+".map"
    load_symbol_use file+".use"
    self
  end
  
  def load_obj(obj_file)
    File.open(obj_file) do |f|
      @bin = f.read.unpack("C*")
    end
  end
  
  def load_symbol_table(file)
    File.open(file).each_line do |line|
      ss = line.split
      case ss[1]
      when "L"
        @symLabel[ss[0].to_i] = ss[2]
      when "l"
        @symExternLable[ss[0].to_i] = ss[2]
      when "V", "v"
        @symVar[ss[0].to_i] = ss[2]
      when "S"
        @symSegment[ss[2]] = ss[0].to_i
      end
    end
  end

  def load_symbol_use(file)
    File.open(file).each_line do |line|
      ss = line.split
      @uses[ss[0].to_i] = ss[1]
    end
  end
    
  def find_symbol_label(name)
    @symLabel.find {|k,v| v==name}
  end

  def find_extern_label(name)
    @symExternLabel.find {|k,v| v==name}
  end
  
  def find_symbol_var(name)
    @symVar.find {|k,v| v==name}
  end
  
  def code_len
    @symSegment[".data"] - @symSegment[".code"]
  end

  def data_len
    @symSegment[".rodata"] - @symSegment[".data"]
  end
  
  def rodata_len
    @bin.size - @symSegment[".rodata"]
  end
    
end