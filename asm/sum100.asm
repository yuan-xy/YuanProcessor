var :a, 100
var :d
MOVi 0, r1 	#sum
MOVi 1, r2		#i
MOVi :a, r7		#test address of a
LOADi :a, r3		#count, value of a
MOVi 1, r4		#step
label :do_sum
	ADD r2, r1, r1	#sum+=i
	ADD r2, r4, r2	#i+=step
	LEQUAL r2, r3, r5 #i<=count
	BRANCH :do_sum, r5
label :exit
	SAVEi r1, :d
EXIT()