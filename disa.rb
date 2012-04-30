#!/usr/bin/ruby

old_e = $embedded 
$embedded = 1
require 'yuan_cpu.rb'
$embedded = old_e

class Disa

  def initialize
    @bin = []
    @symLabel = {}
    @symVar = {}
    @symSegment = {}
    @cur_insn = []    
  end
  
  def load(obj_file)
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
      when "V"
        @symVar[ss[0].to_i] = ss[2]
      when "S"
        @symSegment[ss[0].to_i] = ss[2]
      end
    end
  end
  
  def find_symbol_label(name)
    @symLabel.find {|k,v| v==name}
  end

  def find_symbol_var(name)
    @symVar.find {|k,v| v==name}
  end
  
  def find_symbol_segment(name)
    @symSegment.find {|k,v| v==name}
  end
    
  def reg(a)
    "r" + a.to_s
  end
  
  def decode_address(insn_name,a,b)
    if insn_name=="BRANCH"
      addr = sign_half_word(a,b)
    else
      addr = half_word(a,b)
      if insn_name=="CALL"
        symbol = @symLabel[addr]
      else
        symbol = @symVar[addr]
      end
    end
    if symbol
      puts symbol
      ":"+symbol   #may cast immidiate to symbol address in MOVi
    else
      addr.to_s
    end
  end
  
  def decode_insn_param(insn,values)
    a,b,c = values
    insn_param = insn[1..-1]
    idx = insn_param.index("i")
    if idx==0
      decode_address(insn[0],a,b) + ", " + reg(c)
    elsif idx==1
      reg(a) + ", " + decode_address(insn[0],b,c)
    else
      ret = ""
      insn_param.each_with_index do |k,i|
        break if k==0
        raise "unrecognized mode: #{k}" if k!="r" 
        ret << reg(values[i])
        ret << ","
      end
      return ret[0..-2]
    end
  end
  
  def dis
    printf "Address\tInstruction\tDisassemble"
    in_code_section = true
    @bin.each_with_index do |x,i|
      if i%4==0
        symbol = @symLabel[i]
        if symbol && symbol[0]=="L"
          printf "\nlable :#{symbol[1]}"
        end
        printf "\n%x\t" % i 
        @cur_insn = []
      end
      printf "%x," % x
      @cur_insn << x
      if i%4==3 && in_code_section
        begin
          insn_name = $INSNs[@cur_insn[0]][0]
          insn_para = decode_insn_param($INSNs[@cur_insn[0]],@cur_insn[1..-1])
          printf "\t#{insn_name}(#{insn_para})"
        rescue Exception => error
          puts error.backtrace
          puts "\t probably not code section from here!"
          in_code_section = false
        end
      end
    end
    printf "\n"
  end

  def run(file="a.out")
    load(file)
    load_symbol_table(file+".map")
    dis()
  end
    
end

unless $embedded
  if ARGV.size==0
    Disa.new.run
  else
    Disa.new.run(ARGV[0])
  end
end


