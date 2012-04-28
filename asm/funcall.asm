MOVi 1, :r1
MOVi 2, :r2
PUSH :r1
PUSH :r2
POP :r5
POP :r6
PUSH :sp
POP :sp
CALL :ret
EXIT()

label :ret
	MOVi 3, :r1
	RET()