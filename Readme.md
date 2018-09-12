# Quantum Information for Developers
[![Docker Build Status](https://img.shields.io/docker/build/westernmagic/quid.svg)](https://hub.docker.com/r/westernmagic/quid/)

# Installation
```
	docker pull westernmagic/quid:2018
	# See docker create --help for details
	docker create \
		--interactive \
		--tty \
		--publish 8888:8888 \
		--restart unless-stopped \
		--volume $(pwd):/root/share \
		--name quid_2018 \
		westernmagic/quid:2018
```

# Running
```
	docker start  quid_2018
	docker attach quid_2018
```
