var :a
LOADi 0, r1
MOVi 2, r2
MOVi 3, r3
ADD r2, r3, r5
SAVEi r5, 0
SAVEi r5, :a
LOADi :a, r6
MOVi :a, r7
LOAD r7, r8
EXIT()