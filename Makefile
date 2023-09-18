.PHONY: help

HOSTNAME := $(shell hostname)
UID := $(shell id -u)
GID := $(shell id -g)


help:
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[1;32m%-10s\033[0m %s\n", $$1, $$2}'

build:    ## Build image capable of using fp16/32 models
	docker build -t topaz-vai .

login:    ## Refresh the auth.tpz license file
	docker run --net=host --gpus all --rm -ti --user $(UID):$(GID) -v $(PWD)/auth:/auth --name topaz-login --hostname $(HOSTNAME) topaz-vai login

test:     ## Run a smoke test doing a 2x upscale with Iris
	docker run --rm -ti --gpus all --user $(UID):$(GID) --name vai-test --hostname $(HOSTNAME) \
		-v $(PWD)/models:/models \
		-v $(PWD)/auth/auth.tpz:/opt/TopazVideoAIBETA/models/auth.tpz \
		-v $(PWD):/workspace \
		topaz-vai \
		ffmpeg -y -f lavfi -i testsrc=duration=12:size=320x180:rate=15 -pix_fmt yuv420p \
		-flush_packets 1 -sws_flags spline+accurate_rnd+full_chroma_int \
		-color_trc 2 -colorspace 2 -color_primaries 2 \
		-filter_complex "tvai_up=model=iris-1:scale=2:preblur=-0.6:noise=0:details=1:halo=0.03:blur=1:compression=0:estimate=20:blend=0.8:device=0:vram=1:instances=1" \
		-c:v h264_nvenc -profile:v high -preset medium -pix_fmt yuv420p -b:v 0 \
		sample_iris_2x_upscaled.mp4
