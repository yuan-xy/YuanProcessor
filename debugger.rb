#!/usr/bin/ruby

old_e = $embedded 
$embedded = 1
require 'yuan_cpu.rb'
require 'bin_util.rb'
$embedded = old_e

class Debugger

  def initialize
    @cpu = YuanCpu.new
    @bin = BinUtil.new
    @breaks = {}
  end


  def run(file="a.out")
    @bin.load_symbol_table(file+".map")
    @cpu.load(file)
    while true
      ip = @cpu.reg(:ip)
      printf "> "
      command = readline.chomp
      case command
      when "run" , "r"
        @cpu.run
      when  /b(reak)? (.*)/
        addr = command.split[1].to_i
        if addr%4==0
          @breaks[addr] = @cpu.mem[addr]
          @cpu.mem[addr] = insn_id("BKP")
        else
          puts "can only break at address of 4 multipler"
        end
      when "mem"
        puts @cpu.mem[ip..ip+3]
      when "cont" , "c"
        @cpu.mem[ip] = @breaks[ip]
        @cpu.run
      when "next" , "n"
        #todo: check not exceed code segment
        @cpu.mem[ip] = @breaks[ip]
        @breaks[ip+4] = @cpu.mem[ip+4]
        @cpu.mem[ip+4] = insn_id("BKP")
        @cpu.run
      when "regs"
        @cpu.print_regs
      when  /p(rint)? (.*)/
        name = command.split[1]
        sym =  @bin.find_symbol_label(name)
        puts sym
        unless sym.nil?
          puts "Label #{name}'s address is #{sym[0]}"; next 
        end
        sym =  @bin.find_symbol_var(name)
        unless sym.nil?
          puts "Variable #{name} (address #{sym[0]}): #{@cpu.mem_word sym[0] }"; next
        end
        puts "symbol #{name} can't be found."
      when "quit" , "exit" , "q"
        break
      end
    end
  end
    
end

unless $embedded
  if ARGV.size==0
    Debugger.new.run
  else
    Debugger.new.run(ARGV[0])
  end
end


