#!/usr/bin/ruby

$STACK_INIT = 0xF000

class YuanCpu
  attr_reader :mem
  
  
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
  
  def reg_index(name)
    @reg_names.index(name)
  end
  
  def reg(name)
    @regs[reg_index(name)]
  end
  
  def reg_set(name,value)
    @regs[reg_index(name)] = value
  end
  
  def OR(a, b, c)
    @regs[c] = @regs[a] | @regs[b]
  end

  def AND(a, b, c)
    @regs[c] = @regs[a] & @regs[b]
  end

  def NOT(a, b)
    @regs[a]==0?  @regs[b] = 1 : @regs[b] = 0
  end  
  
  def ADD(a, b, c)
    @regs[c] = @regs[a] + @regs[b]
  end
  
  def SUB(a, b, c)
    @regs[c] = @regs[a] - @regs[b]
  end
  
  def LOAD(a, b)
    @regs[b] = @mem[@regs[a]]
  end

  def LOADi(a, b, c)
    @regs[c] = @mem[(a<<8) + b]
  end
  
  def MOV(a, b)
    @regs[b] = @regs[a]
  end 

  def MOVi(a, b, c)
    @regs[c] = (a<<8) + b
  end
      
  def SAVE(a, b)
    @mem[@regs[b]] = @regs[a]
  end

  def SAVEi(a, b, c)
    @mem[(b<<8) + c] = @regs[a]
  end  
  
  def JMP(a)
    @regs[0] = @regs[a]
  end

  def sign_half_word(a,b)
    diff = (a<<8) + b
    diff -= 0x10000 if a>0x7F
    diff
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

  def INC(a)
    @regs[a] += 1
  end
  
  def DEC(a)
    @regs[a] -= 1
  end

  def PUSH(a)
    addr = reg(:sp)
    SAVE a, reg_index(:sp)
    reg_set (:sp, addr+1)
  end

  def POP(a)
    #puts "before pop %d" % reg(:sp)
    addr = reg(:sp)
    reg_set (:sp,addr-1)
    #puts "in pop %d" % reg(:sp)
    LOAD reg_index(:sp), a
    #puts "after pop %d" % reg(:sp)
  end

  def CALL(a,b)
    PUSH reg_index(:ip)
    PUSH reg_index(:sp)
    @regs[0] = (a<<8)+b
  end
  
  def RET
    POP reg_index(:sp) 
    POP reg_index(:ip)
  end
  
  def load(obj_file)
    File.open(obj_file) do |f|
      @mem = f.read.unpack("C*")
    end
    puts "program @mem size: %d" % @mem.size
    #100000.times {|x| @mem << 0} #stack area
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
      puts "opcode:#{opcode} (#{a},#{b},#{c})"
      case opcode
      when 0
        # NOP
      when 1
        OR(a,b,c)
      when 2
        AND(a,b,c)
      when 3
        NOT(a,b)        
      when 4
        ADD(a,b,c)       
      when 5
        SUB(a,b,c)
      when 6
        LOAD(a,b)
      when 7
        LOADi(a,b,c)
      when 8
        MOV(a,b)
      when 9
        MOVi(a,b,c)        
      when 10
        SAVE(a,b,c)       
      when 11
        SAVEi(a,b,c)
      when 12
        JMP(a)        
      when 13
        BRANCH(a,b,c)
      when 14
        EQUAL(a,b,c)
      when 15
        GEQUAL(a,b,c)
      when 16
        LEQUAL(a,b,c)        
      when 17
        GREAT(a,b,c)
      when 18
        LESS(a,b,c) 
      when 19
        NEQUAL(a,b,c)        
      when 20
        INC(a)
      when 21
        DEC(a)  
      when 22
        PUSH(a)
      when 23
        POP(a)
      when 24
        CALL(a,b)
      when 25
        RET()
      else
        raise "invalid opcode: #{opcode}!"
        break
      end
      #puts "current stack (#{stack.size}): " + stack.join(",") unless stack.nil?
    end
    unless $embedded
      @regs.each_with_index do |x,i|
        puts "#{@reg_names[i]} value: %s" % x
      end
    end
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






