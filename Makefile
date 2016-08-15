systest/systest.bin: systest/systest.asm
	k12aasm -o $@ -f binary $<
systest/systest.rmh.dat: systest/systest.asm
	k12aasm -o $@ -f readmemh $<
