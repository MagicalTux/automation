# Automation

These scripts are used internally by MagicalTux.

## Install Apache

	cd /usr/src
	wget https://raw.githubusercontent.com/MagicalTux/automation/master/get_apache.sh
	chmod +x get_apache.sh
	./get_apache.sh

## docker

	DOCKER_BUILDKIT=1 docker build -t phpbase .
