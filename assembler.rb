#!/usr/bin/ruby

old_e = $embedded 
$embedded = 1
require 'yuan_cpu.rb'
$embedded = old_e

CPU = YuanCpu.new
Text = []
Labels = []
Statics = {}
Consts = {}
Vars = {}
Literals = {}

def make_label(name = "")
  name = name.to_s
  name = "label_%d" % Labels.size if name.empty?
  Labels.push name
  return name
end


def label(name) Text.push "#" + name.to_s end

def code(value) Text.push value end
  
def code_imm_or_address(a)
  if a.class == Fixnum
    code(a >> 8)
    code(0xFF & a)
  else
    code a
  end
end

def literal(value)
  name = "str_%d" % Literals.size
  Literals[name] = value
  return name
end

def static(*names)
  names.each { |name| Statics[name] = 0 }; names
end

def var(count = 1)
  names = []
  count.times { Vars[(names.push "var_%d" % Vars.size).last] = 0 }
  return names
end

def const(value)
  return Consts[value] if Consts.has_key? value
  Consts[value] = "const_%d" % Consts.size
end



def OR(a, b, c)
  code 1
  code CPU.reg_index(a)
  code CPU.reg_index(b)
  code CPU.reg_index(c)
end

def AND(a, b, c)
  code 2
  code CPU.reg_index(a)
  code CPU.reg_index(b)
  code CPU.reg_index(c)
end

def NOT(a, b)
  code 3
  code CPU.reg_index(a)
  code CPU.reg_index(b)
  code 0
end

def ADD(a, b, c)
  code 4
  code CPU.reg_index(a)
  code CPU.reg_index(b)
  code CPU.reg_index(c)
end

def _ADDi(a, b, c)
  MOVi(b,c)
  ADD(a,c,c)
end
  
def SUB(a, b, c)
  code 5
  code CPU.reg_index(a)
  code CPU.reg_index(b)
  code CPU.reg_index(c)
end

def _SUBi(a, b, c)
  MOVi(b,c)
  SUB(a,c,c)
end

def LOAD(a, b)
  code 6
  code CPU.reg_index(a)
  code CPU.reg_index(b)
  code 0
end

def LOADi(a, b)
  code 7
  code_imm_or_address(a)
  code CPU.reg_index(b)
end

def MOV(a, b)
  code 8
  code CPU.reg_index(a)
  code CPU.reg_index(b)
  code 0
end

def MOVi(a, b)
  code 9
  code_imm_or_address(a)
  code CPU.reg_index(b)
end

def SAVE(a, b)
  code 10
  code CPU.reg_index(a)
  code CPU.reg_index(b)
  code 0
end

def SAVEi(a, b)
  code 11
  code CPU.reg_index(a)
  code_imm_or_address(b)
end

def JMP(a)
  code 12
  code CPU.reg_index(a)
  code 0
  code 0
end

def BRANCH(a, b, c)
  code 13
  code CPU.reg_index(a)
  code CPU.reg_index(b)
  code CPU.reg_index(c)
end

def EXIT
  MOVi(0xFFFF,:ip)
end


class Assembler
    
  def self.parse(asm_file)
    load asm_file
  end
  
  def self.dump(obj_file)
    
    assembly = []
    Text.each { |x| assembly.push x }
    Vars.each { |k, v| assembly.push "#%s" % k, v }
    Statics.each { |k, v| assembly.push "#%s" % k, v }
    Consts.each { |k, v| assembly.push "#%s" % v, k }
    Literals.each do |k, v|
      assembly.push "#%s" % k
      v.each_byte { |x| assembly.push x }
    end
    
    offset = 0
    labels = {}
    assembly.each do |x|
      if x.class == Fixnum
        offset = offset + 1
      else
        if x.start_with? '#'
          labels[x[1..-1]] = offset # get the address of label
        else 
          offset = offset + 2 # ref to label, 16bit
        end
      end
    end
    
    #debugger
    
    # Remove all list having labels.
    assembly.delete_if { |x| x.to_s.start_with? "#" }
    
    # Substitute labels by values.
    assembly2 = []
    assembly.each do |x| 
      if x.class==String ||  x.class==Symbol
        tmpx = labels[x.to_s.strip]
        assembly2 << (tmpx >> 8)
        assembly2 << (0xFF & tmpx)
      else
        assembly2 << x
      end
    end
    
    #puts assembly

    File.open(obj_file,"wb") do |f|
      f << assembly2.pack("C*")
    end
  end
  
  def self.asm(asm_file, obj_file="a.out")
    Assembler.parse(asm_file)
    Assembler.dump(obj_file)
  end
end


unless $embedded
  if ARGV.size==0
    puts "usage: ruby #{__FILE__} asm_file [obj_file]"
    exit
  elsif ARGV.size==1
    Assembler.asm(ARGV[0])
  else
    Assembler.asm(ARGV[0],ARGV[1])
  end
end

