.PHONY: sleep
.SECONDARY:

# prevent called libraries from parallelizing
export OMP_NUM_THREADS=1

FSL_DIR="this is not a directory"

sleep: hexdump.txt 

fslhome: fslhome.txt

sleep.txt:
	lensleep=`shuf -i 1-10 -n 1` ;\
	echo "slept for $$lensleep""s" > $@ ;\

hexdump.txt: sleep.txt
	hd $< >$@

fslhome.txt:
	echo $(FSL_DIR) > $@

newer: not-orig
	echo "bar" > newer

test-%:
	@echo "$* is '$($*)'"
