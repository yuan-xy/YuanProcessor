MOVi 1, :r1		
MOVi 2, :r2
MOVi 0, :r3
MOV :r3, :r6
ADD  :r1, :r2, :r1	#r1=3
_ADDi :r1, 4, :r3	#r3=7
SUB  :r3, :r2, :r4	#r4=5
_SUBi :r4, 1, :r5	#r5=4
OR 	:r6, :r1, :r2	#r2=3
AND	:r6, :r1, :r7	#r7=0
NOT :r6, :r8		#r8=1
NOT :r6, :r6		#r6=1

EXIT()