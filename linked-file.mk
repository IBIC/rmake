.PHONY: sleep

sleep: sleep.txt

sleep.txt:
	lensleep=`shuf -i 1-10 -n 1` ;\
	echo "slept for $$lensleep""s" > $@

test-%:
	@echo "$* is '$($*)'"