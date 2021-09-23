.DEFAULT_GOAL := helper
GIT_COMMIT ?= $(shell git rev-parse --short=12 HEAD || echo "NoGit")
BUILD_TIME ?= $(shell date -u '+%Y-%m-%d_%H:%M:%S')
TEXT_RED = \033[0;31m
TEXT_BLUE = \033[0;34;1m
TEXT_GREEN = \033[0;32;1m
TEXT_NOCOLOR = \033[0m

helper: # Adapted from: https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@echo "Available targets..." # @ will not output shell command part to stdout that Makefiles normally do but will execute and display the output.
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

checks:
ifndef TCPDUMP_BUCKET
	echo "TCPDUMP_BUCKET not set"
	exit 1
endif

build: ## Builds the image
	docker build -t debugger .

test: checks clean ## Runs through configured tests
	# Testing running of container
	docker run -dit --name debugger-webserver -p 8023:80 -p 8022:8022 debugger

	# Testing the webserver
	curl -f localhost:8023

	# Testing sshd
	ssh -i ~/.ssh/testing -p 8022 root@localhost -- ip addr

	# Cleanup
	docker logs debugger-webserver
	docker stop -t 2 debugger-webserver && docker rm debugger-webserver

	# Testing TCPdump pushing
	docker run -dit --name debugger-tcpdump -v ~/.aws/:/root/.aws/ -e TCPDUMP_BUCKET=$(TCPDUMP_BUCKET) -p 8023:80 -p 8022:8022 debugger
	for i in `seq 1 22`; do DATE=`date`; echo -n "Iteration No.: $$i - $$DATE - Response: "; curl localhost:8023; sleep 3; done
	aws s3 ls $(TCPDUMP_BUCKET)/tcpdumps/

	# Cleanup
	docker logs debugger-tcpdump
	docker stop -t 2 debugger-tcpdump && docker rm debugger-tcpdump

clean: ## Cleans up all resources used during testing
	-docker stop debugger-webserver;  docker stop debugger-tcpdump; docker rm debugger-webserver; docker rm debugger-tcpdump;
