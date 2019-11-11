RANDOM:=$(shell bash -c 'echo $$RANDOM')
IMAGE:=image-${RANDOM}
ARGS?="-n 5"

run: image
	docker run ${IMAGE} ${ARGS}
#	docker rmi --force ${IMAGE}

image: countdown
	docker build -t ${IMAGE} .

countdown: countdown.c
	@gcc -static $< -o $@

