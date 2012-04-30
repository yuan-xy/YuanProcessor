#!/usr/bin/ruby

old_e = $embedded 
$embedded = 1
require 'yuan_cpu.rb'
$embedded = old_e

class Assembler
  
  def initialize
    @Text = []
    @Labels = []
    @Consts = {}
    @Vars = {}
    @Literals = {}
    @CPU = YuanCpu.new
    @CPU.reg_names.each do |x|
      instance_eval "@#{x} = #{@CPU.reg_index(x)}"
      Assembler.class_eval "attr_reader :#{x}"
    end
    $INSNs.each_with_index do |insn,idx|
      argc = insn_argc(insn)
      args = " a,b,c"[0,argc*2]
      argc>0? comma="," : comma = ""
      s = %Q{
        def #{insn[0]}(#{args})
          gen_code(#{idx} #{comma} #{args})
        end
      }
      na = insn[0]
      unless na=="LOADi" || na=="MOVi" || na=="SAVEi" || na=="BRANCH" || na=="CALL"
        Assembler.class_eval s 
      end
    end
  end

  def make_label
    name = "label_#{@Labels.size}".to_sym
    @Labels.push name
    return name
  end


  def label(name)
    @Labels.push name
    @Text.push "#" + name.to_s 
  end

  def code(value) @Text.push value end

  def code_imm_or_address(a)
    if a.class == Fixnum
      code(a >> 8)
      code(0xFF & a)
    else
      code a
    end
  end

  def literal(value)
    name = "str_%d" % @Literals.size
    @Literals[name] = value
    return name
  end

  def var(name, value=0)
    @Vars[name] = value
  end

  def const(value)
    return @Consts[value] if @Consts.has_key? value
    @Consts[value] = "const_%d" % @Consts.size
  end


  def gen_code(index,a=0,b=0,c=0)
    code index
    code(a)
    code(b)
    code(c)
  end

  def LOADi(a, b)
    code insn_id("LOADi")
    code_imm_or_address(a)
    code b
  end

  def MOVi(a, b)
    code insn_id("MOVi")
    code_imm_or_address(a)
    code b
  end

  def SAVEi(a, b)
    code insn_id("SAVEi")
    code a
    code_imm_or_address(b)
  end

  def BRANCH(a, b)
    code insn_id("BRANCH")
    labl = make_label
    @Text.push "@" + a.to_s + " " + labl.to_s
    code b
    label labl
  end

  def CALL(a)
    code insn_id("CALL")
    code a
    code 0
  end

  def _ADDi(a, b, c)
    raise "8bit imm only support range -128 ~ 127" if(b>127||b<-128) 
    raise "src and dest reg cann't be same" if a==c
    MOVi(b,c)
    ADD(a,c,c)
  end
  def _SUBi(a, b, c)
    raise "8bit imm only support range -128 ~ 127" if(b>127||b<-128) 
    raise "src and dest reg cann't be same" if a==c
    MOVi(b,c)
    SUB(a,c,c)
  end

  def EXIT
    MOVi(0xFFFF, ip)
  end
  
    
  def eval_file(file)
    instance_eval File.read(file), file
  end
  
  def dump(obj_file)
    
    asmb = []
    asmb.push "#.code"
    @Text.each { |x| asmb.push x }
    asmb.push "#.data"
    @Vars.each { |k, v| asmb.push "#%s" % k;  word_to_char4(v).each{|vc| asmb.push vc}  }
    asmb.push "#.rodata"
    @Consts.each { |k, v| asmb.push "#%s" % v, k }
    @Literals.each do |k, v|
      asmb.push "#%s" % k
      v.each_byte { |x| asmb.push x }
    end
    
    offset = 0
    labels = {}
    asmb.each do |x|
      if x.class == Fixnum
        offset = offset + 1
      else
        if x.to_s.start_with? '#'
          labels[x[1..-1]] = offset # get the address of label
        else
          offset = offset + 2 # ref to label, 16bit
        end
      end
    end
    
    # Substitute labels by values.
    asmb2 = []
    asmb.each do |x| 
      next if x.to_s.start_with? "#"
      if x.class==String ||  x.class==Symbol
        if x.to_s.start_with? '@'
          dest, cur = x[1..-1].split(" ")
          diff = labels[dest] - labels[cur]
          #puts "cur:#{cur}, dest:#{dest}, diff:#{diff}"
          asmb2 << (diff >> 8)
          asmb2 << (0xFF & diff)
        else
          tmpx = labels[x.to_s.strip]
          asmb2 << (tmpx >> 8)
          asmb2 << (0xFF & tmpx)
        end  
      else
        asmb2 << x
      end
    end
    
    File.open(obj_file,"wb") do |f|
      f << asmb2.pack("C*")
    end
    
    File.open(obj_file+".map","wb") do |f|
      @Labels.each do |lb|
        name = lb.to_s
        f << labels[name]
        f << " L "
        f << name
        f << "\n"
      end
      @Vars.each do |k,v|
        f << labels[k.to_s]
        f << " V "
        f << k
        f << " %d" % v
        f << "\n"
      end
      labels.find_all{|k,v| k[0]=="."[0]}.each do |k,v|
        f << v
        f << " S "
        f << k
        f << "\n"
      end
    end
  end
  
  def asm(asm_file, obj_file="a.out")
    eval_file(asm_file)
    dump(obj_file)
  end
end


unless $embedded
  if ARGV.size==0
    puts "usage: ruby #{__FILE__} asm_file [obj_file]"
    exit
  elsif ARGV.size==1
    Assembler.new.asm(ARGV[0])
  else
    Assembler.new.asm(ARGV[0],ARGV[1])
  end
end

