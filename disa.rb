#!/usr/bin/ruby

old_e = $embedded 
$embedded = 1
require 'yuan_cpu.rb'
$embedded = old_e

class Disa
  @bin = []
  @cur_insn = []
  
  def load(obj_file)
    File.open(obj_file) do |f|
      @bin = f.read.unpack("C*")
    end
  end
  
  def reg(a)
    ":r" + a.to_s
  end
  
  def decode_insn_param(klazzs,values)
    a,b,c = values
    idx_a = klazzs.index("a")
    idx_i = klazzs.index("i")
    if idx_a.nil?
      idx = idx_i
    else
      idx = idx_a
    end
    if idx==0
      half_word(a,b).to_s + ", " + reg(c)
    elsif idx==1
      reg(a) + ", " + half_word(b,c).to_s
    else
      ret = ""
      klazzs.each_with_index do |k,i|
        break if k=="0"
        raise "unrecognized mode: #{k}" if k!="r" 
        ret << reg(values[i])
      end
      return ret
    end
  end
  
  def dis
    printf "Address\tInstruction\tDisassemble"
    in_code_section = true
    @bin.each_with_index do |x,i|
      if i%4==0
        printf "\n%x\t" % i 
        @cur_insn = []
      end
      printf "%x," % x
      @cur_insn << x
      if i%4==3 && in_code_section
        begin
          insn_name = $INSNs[@cur_insn[0]][0]
          insn_para = decode_insn_param($INSNs[@cur_insn[0]][1..-1],@cur_insn[1..-1])
          printf "\t#{insn_name}(#{insn_para})"
        rescue
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


