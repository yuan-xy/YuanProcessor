#!/usr/bin/ruby

old_e = $embedded 
$embedded = 1
require 'yuan_cpu.rb'
require 'bin_util.rb'
$embedded = old_e

class Linker
  class AddressMap
    attr_accessor :code_old, :code_new, :data_old, :data_new, :rodata_old, :rodata_new
    
    def to_s
      puts "#{code_old}\t#{code_new}\n"+
      "#{data_old}\t#{data_new}\n"+"#{rodata_old}\t#{rodata_new}\n\n"
    end
  end
  
  def initialize
    @bins = []
    @ams = []
  end

  def link(files)
    files.each do |f| 
      @bins << BinUtil.new.load(f)
      @ams << AddressMap.new
    end
    start=0
    @bins.each_with_index do |bin,i|
      @ams[i].code_old = bin.symSegment[".code"]
      @ams[i].code_new = start
      start += bin.code_len
    end
    @bins.each_with_index do |bin,i|
      @ams[i].data_old = bin.symSegment[".data"]
      @ams[i].data_new = start
      start += bin.data_len
    end    
    @bins.each_with_index do |bin,i|
      @ams[i].rodata_old = bin.symSegment[".rodata"]
      @ams[i].rodata_new = start
      start += bin.rodata_len
    end
    gSymbols = {}
    @bins.each_with_index do |bin,i|
      bin.symLabel.each do |k,v|
        gSymbols[v] = k + @ams[i].code_new - @ams[i].code_old
      end
      bin.symVar.each do |k,v|
        gSymbols[v] = k + @ams[i].data_new - @ams[i].data_old
      end
    end
    gSymbols.each {|k,v| puts "#{k} => #{v}"}
    @bins.each do |bin|
      bin.uses.each do |address,name|
        bin.bin[address..address+1] = word_to_char2(gSymbols[name])
      end
    end
    File.open("a.out","wb") do |f|
      @bins.each_with_index do |bin,i|
        f << bin.bin[0..(bin.code_len-1)].pack("C*")
      end
      @bins.each_with_index do |bin,i|
        f << bin.bin[bin.code_len..(bin.code_len+bin.data_len-1)].pack("C*")
      end
    end
  end
    
end

unless $embedded
  if ARGV.size < 2
    puts "usage: linker obj1 obj2 [obj3 ...]"
  else
    Linker.new.link(ARGV)
  end
end


