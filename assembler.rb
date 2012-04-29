#!/usr/bin/ruby

old_e = $embedded 
$embedded = 1
require 'yuan_cpu.rb'
$embedded = old_e

class Assembler
  
  def initialize
    @CPU = YuanCpu.new
    @CPU.reg_names.each do |x|
      instance_eval "@#{x} = #{@CPU.reg_index(x)}"
      Assembler.class_eval "attr_reader :#{x}"
    end
    
    puts "@CPU.reg_index(0) = %x " % @CPU.reg_index(0)
    @Text = []
    @Labels = []
    @Consts = {}
    @Vars = {}
    @Literals = {}
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

  def vars(value=0, count = 2)
    names = []
    count.times { names.push var(value) }
    return names
  end

  def const(value)
    return @Consts[value] if @Consts.has_key? value
    @Consts[value] = "const_%d" % @Consts.size
  end


  def gen_code(index,a=0,b=0,c=0)
    code index
    a==0? code(0) : code(a)
    b==0? code(0) : code(b)
    c==0? code(0) : code(c)
  end

  def OR(a, b, c) gen_code(1,a,b,c)  end
  def AND(a, b, c) gen_code(2,a,b,c)  end
  def NOT(a, b)  gen_code(3,a,b)  end
  def ADD(a, b, c) gen_code(4,a,b,c)  end
  def SUB(a, b, c)  gen_code(5,a,b,c)  end
  def LOAD(a, b) gen_code(6,a,b)  end

  def LOADi(a, b)
    code 7
    code_imm_or_address(a)
    code b
  end

  def MOV(a, b) gen_code(8,a,b)  end

  def MOVi(a, b)
    code 9
    code_imm_or_address(a)
    code b
  end

  def SAVE(a, b) gen_code(10,a,b)  end

  def SAVEi(a, b)
    code 11
    code a
    code_imm_or_address(b)
  end

  def JMP(a) gen_code(12,a)  end

  def BRANCH(a, b)
    code 13
    labl = make_label
    @Text.push "@" + a.to_s + " " + labl.to_s
    code b
    label labl
  end

  def EQUAL(a, b, c) gen_code(14,a,b,c) end
  def GEQUAL(a, b, c) gen_code(15,a,b,c) end
  def LEQUAL(a, b, c) gen_code(16,a,b,c) end
  def GREAT(a, b, c) gen_code(17,a,b,c) end
  def LESS(a, b, c) gen_code(18,a,b,c) end
  def NEQUAL(a, b, c) gen_code(19,a,b,c) end
  def INC(a) gen_code(20,a) end
  def DEC(a) gen_code(21,a) end
  def PUSH(a) gen_code(22,a) end
  def POP(a) gen_code(23,a) end

  def CALL(a)
    code 24
    code a
    code 0
  end
  def RET() gen_code(25) end


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
    
    assembly = []
    @Text.each { |x| assembly.push x }
    @Vars.each { |k, v| assembly.push "#%s" % k, v }
    @Consts.each { |k, v| assembly.push "#%s" % v, k }
    @Literals.each do |k, v|
      assembly.push "#%s" % k
      v.each_byte { |x| assembly.push x }
    end
    
    offset = 0
    labels = {}
    assembly.each do |x|
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
    
    puts assembly
    
    # Substitute labels by values.
    assembly2 = []
    assembly.each do |x| 
      next if x.to_s.start_with? "#"
      if x.class==String ||  x.class==Symbol
        if x.to_s.start_with? '@'
          dest, cur = x[1..-1].split(" ")
          diff = labels[dest] - labels[cur]
          puts "cur:#{cur}, dest:#{dest}, diff:#{diff}"
          assembly2 << (diff >> 8)
          assembly2 << (0xFF & diff)
        else
          tmpx = labels[x.to_s.strip]
          assembly2 << (tmpx >> 8)
          assembly2 << (0xFF & tmpx)
        end  
      else
        assembly2 << x
      end
    end
    
    File.open(obj_file,"wb") do |f|
      f << assembly2.pack("C*")
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
        f << labels[v]
        f << " V "
        f << v
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

