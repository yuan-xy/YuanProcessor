#!/usr/bin/ruby

$embedded = true

require 'yuan_cpu.rb'
require 'test/unit'


class TestRoman < Test::Unit::TestCase
      def test_basic
        load 'assembler.rb'
        Assembler.asm("asm/basic.asm")
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
      
      def test_load_store
        load 'assembler.rb'
        Assembler.asm("asm/load_store.asm")
        cpu = YuanCpu.new
        cpu.load_run
        assert_equal(7, cpu.reg(:r1))
        assert_equal(0, cpu.reg(:r2))
        assert_equal(1, cpu.reg(:r3))
        assert_equal(0, cpu.reg(:r4))
        assert_equal(1, cpu.reg(:r5))
        assert_equal(1, cpu.reg(:r6))
        assert_equal(40, cpu.reg(:r7))
        assert_equal(cpu.reg(:r6), cpu.reg(:r8))
      end
      
end
