default:
	echo "Please run a specific target as this first one will do nothing."

checks:
ifndef BUCKET
	echo "BUCKET not set"
	exit 1
endif

build:
	docker build -t debugger .

test: checks
	# Testing running of container
	docker run -dit --name debugger-webserver -e TCPDUMP=false -p 8023:80 -p 8022:8022 debugger

	# Testing the webserver
	curl -f localhost:8023

	# Testing sshd
	# ssh -i ~/.ssh/testing -p 8022 root@localhost -- ip addr

	# Cleanup
	docker logs debugger-webserver
	docker stop -t 2 debugger-webserver && docker rm debugger-webserver

	# Testing TCPdump pushing
	docker run -dit --name debugger-tcpdump -v ~/.aws/:/root/.aws/ -e BUCKET=$(BUCKET) -e TCPDUMP=true -p 8023:80 -p 8022:8022 debugger
	for i in {1..20}; do curl localhost:8023; sleep 10; done
	aws s3 ls $(BUCKET)/tcpdumps/

	# Cleanup
	docker logs debugger-tcpdump
	docker stop -t 2 debugger-tcpdump && docker rm debugger-tcpdump

clean:
	docker stop debugger-webserver;  docker stop debugger-tcpdump; docker rm debugger-webserver; docker rm debugger-tcpdump; echo OK
