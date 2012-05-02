#!/usr/bin/ruby

$embedded = true

require 'yuan_cpu.rb'
require 'assembler.rb'
require 'disa.rb'
require 'bin_util.rb'
require 'linker.rb'
require 'test/unit'


class TestRoman < Test::Unit::TestCase
      def test_word_char
        assert_equal -1000, char4_to_word(word_to_char4(-1000))
        assert_equal 1000, char4_to_word(word_to_char4(1000))
        assert_equal word_to_char4(256), [0, 0, 1, 0]
      end
      
      def test_basic
        Assembler.new.asm("asm/basic.asm")
        cpu = YuanCpu.new
        cpu.load_run
        assert_equal(3, cpu.reg(:r1))
        assert_equal(3, cpu.reg(:r2))
        assert_equal(7, cpu.reg(:r3))
        assert_equal(5, cpu.reg(:r4))
        assert_equal(4, cpu.reg(:r5))
        assert_equal(1, cpu.reg(:r6))
        assert_equal(0, cpu.reg(:r7))
        assert_equal(1, cpu.reg(:r8))
      end 

      def test_basic2
        Assembler.new.asm("asm/basic2.asm")
        cpu = YuanCpu.new
        cpu.load_run
        assert_equal(-2, cpu.reg(:r3))
        assert_equal(20, cpu.reg(:r4))
        assert_equal(-20, cpu.reg(:r5))
      end
            
      def test_load_store
        Assembler.new.asm("asm/load_store.asm")
        cpu = YuanCpu.new
        cpu.load_run
        assert_equal(insn_id("LOADi"), word_to_char4(cpu.reg(:r1))[0])
        assert_equal(2, cpu.reg(:r2))
        assert_equal(3, cpu.reg(:r3))
        assert_equal(5, cpu.reg(:r5))
        assert_equal(5, cpu.reg(:r6))
        assert_equal(40, cpu.reg(:r7))
        assert_equal(cpu.reg(:r6), cpu.reg(:r8))
      end

      def test_sum100
        Assembler.new.asm("asm/sum100.asm")
        cpu = YuanCpu.new
        cpu.load_run
        assert_equal(1000*1001/2, cpu.reg(:r1))
        assert_equal(1001, cpu.reg(:r2))
        assert_equal(1000, cpu.reg(:r3))
        assert_equal(1, cpu.reg(:r4))
        bin = BinUtil.new
        bin.load_symbol_table("a.out.map")
        addr_d = bin.find_symbol_var("d")[0]
        assert_equal(cpu.mem_word(addr_d), cpu.reg(:r1))
      end

      def test_funcall
        Assembler.new.asm("asm/funcall.asm")
        cpu = YuanCpu.new
        cpu.load_run
        assert_equal(3, cpu.reg(:r1))
        assert_equal(2, cpu.reg(:r2))
        assert_equal(2, cpu.reg(:r5))
        assert_equal(1, cpu.reg(:r6))
        assert_equal($STACK_INIT, cpu.reg(:sp))
      end
      
      def test_fib
        Assembler.new.asm("asm/fib.asm")
        cpu = YuanCpu.new
        cpu.load_run
        assert_equal(55, cpu.reg(:r1))
      end
      
      def test_link
        Assembler.new.asm("asm/link/main.asm", "main.obj")
        Assembler.new.asm("asm/link/sub.asm", "sub.obj")
        Linker.new.link(["main.obj","sub.obj"])
        cpu = YuanCpu.new
        cpu.load_run
        assert_equal(15, cpu.reg(:r1))
        assert_equal(10, cpu.reg(:r2))
      end
                  
end
