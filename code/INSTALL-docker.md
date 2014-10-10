	brew install docker boot2docker

	boot2docker init
	export DOCKER_IP=192.168.59.103
	export DOCKER_HOST=tcp://${DOCKER_IP}:2375
	VBoxManage sharedfolder add boot2docker-vm -name home -hostpath /home/docker
	VBoxManage sharedfolder add boot2docker-vm -name home -hostpath /Users
	boot2docker up
	boot2docker ssh "ls /Users"

	# docker run hello-world
	docker run -it ubuntu bash
	docker share
	docker stop


	cd ~/ics/book/big_data_for_chimps/code
	docker build -t bd4c .
	docker rm bd4c_scratch ; docker run --name bd4c_scratch -i -t bd4c

	boot2docker ssh 'mkdir -p /tmp/deb-proxy ; chmod a+wrx /tmp/deb-proxy'
	docker kill deb-proxy ; docker rm deb-proxy ; docker build -t deb-proxy config/deb-proxy
	docker run --name deb-proxy --rm -v /tmp/deb-proxy:/deb-proxy -p 8000:8000 -it deb-proxy
	
	# remove all stopped containers
	docker rm $(docker ps -a -q)

	# Remove all untagged images
	docker rmi $(docker images | grep '^<none>' | awk '{print $3}')


