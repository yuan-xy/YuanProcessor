#!/usr/bin/ruby

old_e = $embedded 
$embedded = 1
require 'yuan_cpu.rb'
require 'bin_util.rb'
$embedded = old_e

class Disa

  def initialize
    @bin = BinUtil.new
    @cur_insn = []    
  end
  
  def load(obj_file)
    @bin.load obj_file
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
        symbol = @bin.symLabel[addr]
      else
        symbol = @bin.symVar[addr]
      end
    end
    if symbol
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
    @bin.bin.each_with_index do |x,i|
      if i%4==0
        symbol = @bin.symLabel[i]
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


