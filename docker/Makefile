IMAGE:=image-$(shell bash -c 'echo $$RANDOM')
ARGS?="-n 5"

run: image
	docker run ${IMAGE} ${ARGS}

image: countdown
	docker build -t ${IMAGE} .

countdown: countdown.c
	@gcc -static $< -o $@

