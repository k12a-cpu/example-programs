leds_demo/leds_demo.bin: leds_demo/leds_demo.asm
	k12aasm -o $@ -f binary $<
leds_demo/leds_demo.rmh.dat: leds_demo/leds_demo.asm
	k12aasm -o $@ -f readmemh $<
systest/systest.bin: systest/systest.asm
	k12aasm -o $@ -f binary $<
systest/systest.rmh.dat: systest/systest.asm
	k12aasm -o $@ -f readmemh $<
