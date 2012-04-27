#!/usr/bin/ruby

class YuanCpu
  attr_reader :mem
  
  def initialize
    @reg_names = [:ip, :r1, :r2, :r3, :r4, :r5, :r6, :r7, :r8, :sp]
    @regs = [0,0,0,0,0,0,0,0,0,0]
    @mem = []
  end
  
  def reg_index(name)
    @reg_names.index(name)
  end
  
  def reg(name)
    @regs[reg_index(name)]
  end
  
  def reg=(name,value)
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

  def BRANCH(a, b, c)
    @regs[a]? JMP(b) : JMP(c)
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
      else
        raise "invalid opcode: #{opcode}!"
        break
      end
    end
    unless $embedded
      @regs.each_with_index do |x,i|
        puts "#{@reg_names[i]} value: %x" % x
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






