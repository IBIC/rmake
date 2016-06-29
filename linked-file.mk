.PHONY: sleep

sleep: sleep.txt

sleep.txt:
	lensleep=`shuf -i 1-10 -n 1` ;\
	echo "sleeping for $$lensleep s" ;\
	(time sleep $$lensleep) 2> $@

test-%:
	@echo "$* is '$($*)'"