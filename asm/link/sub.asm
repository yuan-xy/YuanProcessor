extern :offset

label :add3
	MOVi 3, r1
	ADD r4, r1, r1
	LOADi :offset, r2
	ADD r1,r2,r1
	RET()