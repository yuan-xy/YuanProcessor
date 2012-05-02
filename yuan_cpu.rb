#!/usr/bin/ruby

$STACK_INIT = 0xF000

# 0:not used,  r:register id,   i:immediate or memory address

$INSNs = [
  ["NOP",0,0,0],
  ["BKP",0,0,0],
  ["OR","r","r","r"],
  ["AND","r","r","r"],
  ["NOT","r","r",0],
  ["NEG","r","r",0],  
  ["INC","r",0,0],
  ["DEC","r",0,0],
  ["ADD","r","r","r"],
  ["SUB","r","r","r"],
  ["MUL","r","r","r"],  
  ["LOAD","r","r",0],
  ["LOADi","i","i","r"],
  ["MOV","r","r",0],
  ["MOVi","i","i","r"],
  ["SAVE","r","r",0],
  ["SAVEi","r","i","i"],
  ["JMP","r",0,0],
  ["BRANCH","i","i","r"],
  ["EQUAL","r","r","r"],
  ["GEQUAL","r","r","r"],
  ["LEQUAL","r","r","r"],
  ["GREAT","r","r","r"],
  ["LESS","r","r","r"],
  ["NEQUAL","r","r","r"],
  ["PUSH","r",0,0],
  ["POP","r",0,0],
  ["CALL","i","i",0],
  ["RET",0,0,0],
  ]

$INSN_SIZE = $INSNs.size  
  
def half_word(a,b)
  (a<<8) + b
end
  
def sign_half_word(a,b)
  diff = (a<<8) + b
  diff -= 0x10000 if a>0x7F
  diff
end

def word_to_char2(w)
  a = (w >> 8)
  b = (0xFF & w)
  [a,b]
end

def word_to_char4(w)
  ret = []
  arr = []
  31.downto(0) {|n| arr <<  w[n] }
  arr.each_slice(8).each {|sl| ret << sl.to_s.to_i(2)}
  ret
end

def char4_to_word(arr)
  ret = (arr[0]<<24) + (arr[1]<<16) + (arr[2]<<8) + arr[3]
  ret -= 0x100000000 if arr[0]>0x7F
  ret  
end
    
def insn_argc(insn)
  argc=-1
  insn.each {|x| break if x==0; argc+=1}
  argc-=1 if insn.index("i")
  argc
end

def insn_id(insn_name)
  $INSNs.index{|x| x[0]==insn_name}
end
    
class YuanCpu
  attr_reader :reg_names
  attr_accessor :mem, :regs
  
  def initialize
    @reg_names = [:ip, :r1, :r2, :r3, :r4, :r5, :r6, :r7, :r8, :sp]
    @regs = [0,0,0,0,0,0,0,0,0,$STACK_INIT]
    @mem = []
  end
  
  def stack
    b = $STACK_INIT
    e = reg(:sp)-1
    @mem[b..e]
  end
  
  def mem_word(address)
    char4_to_word @mem[address..address+3]
  end
  
  def reg_index(name)
    @reg_names.index(name)
  end
  
  def reg(name)
    @regs[reg_index(name)]
  end
  
  def reg_set(name,value)
    @regs[reg_index(name)] = value
  end
  
  def print_regs
    @regs.each_with_index do |x,i|
      puts "#{@reg_names[i]} value: %s" % x
    end
  end
  
  def OR(a, b, c)
    @regs[c] = @regs[a] | @regs[b]
  end

  def AND(a, b, c)
    @regs[c] = @regs[a] & @regs[b]
  end

  def NOT(a, b, null=0)
    @regs[a]==0?  @regs[b] = 1 : @regs[b] = 0
  end  

  def NEG(a, b, null=0)
    @regs[b] = -@regs[a]
  end

  def INC(a, null1=0, null2=0)
    @regs[a] += 1
  end
  
  def DEC(a, null1=0, null2=0)
    @regs[a] -= 1
  end
      
  def ADD(a, b, c)
    @regs[c] = @regs[a] + @regs[b]
  end
  
  def SUB(a, b, c)
    @regs[c] = @regs[a] - @regs[b]
  end
  
  def MUL(a, b, c)
    @regs[c] = @regs[a] * @regs[b]
  end
    
  def LOAD(a, b, null=0)
    addr = @regs[a]
    @regs[b] = char4_to_word @mem[addr..addr+3]
  end

  def LOADi(a, b, c)
    addr = (a<<8) + b
    @regs[c] = char4_to_word @mem[addr..addr+3]
  end
  
  def MOV(a, b, null=0)
    @regs[b] = @regs[a]
  end 

  def MOVi(a, b, c)
    @regs[c] = (a<<8) + b
  end
      
  def SAVE(a, b, null=0)
    addr = @regs[b]
    @mem[addr..addr+3] = word_to_char4 @regs[a]
  end

  def SAVEi(a, b, c)
    addr = (b<<8) + c
    @mem[addr..addr+3] = word_to_char4 @regs[a]
  end  
  
  def JMP(a, null1=0, null2=0)
    @regs[0] = @regs[a]
  end

  def BRANCH(a, b, c)
    if @regs[c] == true
      @regs[0] += sign_half_word(a,b)
    end
  end
  
  def EQUAL(a,b,c)
    @regs[c] = (@regs[a] == @regs[b])
  end

  def GEQUAL(a,b,c)
    @regs[c] = (@regs[a] >= @regs[b])
  end

  def LEQUAL(a,b,c)
    @regs[c] = (@regs[a] <= @regs[b])
  end

  def GREAT(a,b,c)
    @regs[c] = (@regs[a] > @regs[b])
  end

  def LESS(a,b,c)
    @regs[c] = (@regs[a] < @regs[b])
  end

  def NEQUAL(a,b,c)
    @regs[c] = (@regs[a] != @regs[b])
  end  

  def PUSH(a, null1=0, null2=0)
    addr = reg(:sp)
    SAVE a, reg_index(:sp)
    reg_set(:sp, addr+4)
  end

  def POP(a, null1=0, null2=0)
    addr = reg(:sp)
    reg_set(:sp,addr-4)
    LOAD reg_index(:sp), a
  end

  def CALL(a,b,null=0)
    PUSH reg_index(:ip)
    PUSH reg_index(:sp)
    @regs[0] = (a<<8)+b
  end
  
  def RET(null1=0, null2=0, null3=0)
    POP reg_index(:sp) 
    POP reg_index(:ip)
  end
  
  def load(obj_file)
    File.open(obj_file) do |f|
      @mem = f.read.unpack("C*")
    end
    puts "program @mem size: %d" % @mem.size   unless $embedded
  end
  
  def run
    while true do
      ip = @regs[0]
      break if ip == 0xFFFF
      opcode = @mem[ip]
      a = @mem[ip + 1]
      b = @mem[ip + 2]
      c = @mem[ip + 3]
      @regs[0] = ip + 4
      insn = "#{$INSNs[opcode][0]}(#{a},#{b},#{c})"
      puts "addr:#{ip} \t #{insn}"  unless $embedded
      case opcode
      when 0
        # NOP
      when 1
        puts "breakpoint at address #{ip} reached."
        @regs[0] = ip
        break # BKP
      when 2..$INSN_SIZE-1
        eval insn
      else
        raise "invalid opcode: #{opcode}!"
      end
      #puts "current stack (#{stack.size}): " + stack.join(",") unless stack.nil?
    end
    print_regs unless $embedded
  end
  
  def load_run(obj_file="a.out")
    load(obj_file)
    run
  end

end


unless $embedded
  if ARGV.size==0
    YuanCpu.new.load_run
  else
    YuanCpu.new.load_run(ARGV[0])
  end
end






