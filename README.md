Yuan Processor
==========

Yuan processor is a simple 32-bit RISC system. I implement assembler, linker , emulator , debugger and dis-assembler for it using ruby programming language just for fun.


##0. Quick Play

assemble and run

    $ ./assembler.rb asm/sum100.asm
    $ ./yuan_cpu.rb


dis-assemble and debug the binary file

    $ ./disa.rb
    $ ./debugger.rb
    > b 4
    > r
    > q


run all tests

    $ ./test.rb
	Finished in 0.131666 seconds.
	8 tests, 34 assertions, 0 failures, 0 errors


##1. Instruction Format

Yuan has 8 general-purpose registers (form r1 to r8) and 2 special registers (ip and sp). All registers are 32-bit wide. Every instruction is four bytes long and has the form

OP X , Y , Z .

The first byte of the instruction is the op code, and the remainder is the operands. If the amount of operands is less than 3, the blank position will be filled by 0. Almost all instruction's operands are register except LOADi, MOVi, SAVEi, CALL and BRANCH. The last operand is always the destination address. For Example:

"ADD r1, r2, r3" means r3 = r1 + r2. The binary code is "8 1 1 1", which is a big-endian fashion.

"LOADi 8, r1"  means load 4 bytes form memory address between 8 to 12 to register r1. The binary code is "0xc 0 8 1". 

Because we only use 2 byte to hold the address, so the maximal addressable memory currently is 2^16 bytes (will be fixed).



##2. Memory Layout

* The system begin execution at memory address 0.
* The first part of the memory is the code segment and then followed by data segment and rodata segment.
* The stack's base address is 0xF000 and is increased upward.
* There is no boundary check for memory access. 


##3. Object File Representation

* The Object File is seperated to three parts: the binary file, the symbol define file and the symbol use file.
* The binary file's structure is same as the main memory, aka. [code / data / rodata]. So it can be load to memory and run directly. 
* The symbol define file record the address of symbols. the "address | symbol type | symbol name". it's suffix is "map".
* The symbol use file record which address use(point to) which symbol. so we can use it to help us relocate symbols in linker. it's suffix is "use".


##4. Call Convention

* function parameters are passed through r4-r1 registers. If the parameters' amount is larger than 4, then the rest parameters are passed through the stack.
* r5-r8 are called saved registers.
* the return value is save in the r1 register.


	todo...