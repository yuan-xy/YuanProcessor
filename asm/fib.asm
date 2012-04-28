	MOVi 10, :r4
	MOVi 1, :r5	
	MOVi 2, :r6
	CALL :fib
label :exit
	EXIT()
label :fib
	EQUAL :r4, :r5, :r7		#i=1, return 1
	BRANCH :fib1, :r7
	EQUAL :r4, :r6, :r7		#i=2, return 1
	BRANCH :fib1, :r7
	DEC :r4	
	PUSH :r4
	CALL :fib
	POP :r4
	PUSH :r1
	DEC :r4
	CALL :fib
	POP :r2
	ADD :r1, :r2, :r1
	RET()
label :fib1
	MOVi 1, :r1
	RET()	