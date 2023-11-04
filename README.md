# Topaz Video AI dockerized

This repository provides a turn-key solution to running Topaz Video AI on Linux (AMD64) in a containerized manner.

## Usage
1. Build the container


   ```sh
   make build
   ```

2. Get an `auth.tpz` file for the machine you'll run the container on:

   ```sh
   make login
   ```

   Follow the two-step instructions presented when invoking the make target.

3. Use VAI via ffmpeg

   ```sh
   make test
   ```

   The command shown contains all the information needed to run the container.

If you want to process clips on the host, just mount the directory containing the files to `/workspace` in the container, and they will appear at the default directory the container uses (CWD).
E.g.

```
docker run --rm -ti --gpus all -hostname $HOSTNAME --user $UID:$GID \
-v $PWD/models:/models \
-v $PWD/auth/auth.tpz:/opt/TopazVideoAIBETA/models/auth.tpz \
-v $PWD:/workspace topaz-vai \
ffmpeg -i clip-from-host.mp4 ...
```

Side-note:

If you want to separate the workspace from the models and license key, just mount those other directories instead.
In my personal setup, I've got the models in /tmp/models on the host, and the license key in my home directory, so the command I use to run the container is instead:

```
docker run --rm -ti --gpus all -hostname $HOSTNAME --user $UID:$GID \
-v /tmp/models:/models \
-v $HOME/.vai/auth.tpz:/opt/TopazVideoAIBETA/models/auth.tpz \
-v $PWD:/workspace topaz-vai \
ffmpeg -i clip-from-host.mp4 ...
```

Where the container looks for the respective files is controlled by the ordinary Topaz environment variables;

* `TVAI_MODEL_DATA_DIR` for the model files (the gigabytes of tpz files downloaded). Defaults to `/models` in the image.
* `TVAI_MODEL_DIR` where ffmpeg looks for the model metadata files (the json files, such as aaa.json). Defaults to the install directory of VAI (`/opt/TopazVideoAIBETA/models`) since the VAI deb package installs all the model metadata files in that exact directory.

So you can change where ffmpeg looks for these two things by overriding those two environment variables when you launch a container. E.g. `docker .... -e TVAI_MODEL_DATA_DIR=/mnt/some-dir -v $MY_HOST_MODEL_DIR:/mnt/some-dir`, but I really don't see a reason anyone would want to. But if _you_ do, then that's how.

## FAQ

### Q1: I have a headless setup, will this work in that context ?

Yes. This project was specifically created to facilitate that use case.
All you need is a valid `auth.tpz` file mounted or copied to the model's directory in the container: `/opt/TopazVideoAIBETA/models/auth.tpz`

### Q2: Will I ever need to refresh the auth.tpz file ?
Yes. The file is only valid for a limited time. How long exactly, Topaz has not disclosed (to my knowledge).

If you run into a problem where the watermark suddenly starts being introduced, it may be because the license file expired. Just redo step 1 in the usage instruction to get a refreshed license file.

### Q3: The `make test` run doesn't the encoding pipeline, just exists, why ?

Most likely because of CUDA out of memory crash. Different versions of the Topaz engine produce different level of error details. _3.3.9 beta_ was very helpful reporting exactly the cause, down to the CUDA function that triggered the OOM. _3.4.4 beta_ seems less helpful and just silently dies prematurely.

The problem seems non-deterministic, and the only way I've found to circumnavigate the issue is to just try the same command again and again. May take as many as 10 attempts, but seems to work about 1/5th of the time.

This is _one bug_ I really hope this repo can help Topaz Labs nail down and fix.

To see if this is the issue for you, run "make test" a number of times. Sometimes it helps to run [nvtop](https://github.com/Syllo/nvtop) in a different terminal on the same machine. Might be that nvtop resets some GPU state that the Topaz code has corrupted (?). Seems to reduce the probability of failure, at least on my ubuntu 22.04.1 host with nvidia driver 535.54.03, CUDA 12.2 and a Geforce 3090.

### Q4: Why this repo?
Two reasons. 

1. To make it as painless as possible for users to run VAI on Linux.
2. To provide both users _and_ Topaz Labs employees a common and reproducible environment that allows for easier reproduction of user reported errors on Linux. Avoids wasted time and unhelpful support responses from Topaz Labs support representatives or engineers, such as _"Unable to reproduce on our bespoke in-house environment"_.

### Q5: Why not publish this image to dockerhub or other popular docker registries ?

Because there may be copyright issues involved. Needs to be cleared with Topaz Labs first in order to determine if this community service can be offered. This has not yet been done.

### Q6: Why not provide a complete VM setup to avoid all variance entirely ?

This is a potential future improvement that is being considered. Right now I haven't been able to make VAI work on any of the AWS GPU instance types, so finding a suitable environment that both Topaz Labs and users can leverage would need to be discussed first. 

For now having at least a common VAI setup that both the provider and customers can use is a first step. That reduces the variance to just the specific hardware used, the host kernel version and the specific NVIDIA driver used on the host. The rest is standardized in the container image.

### Q7: With the license key mounted, I still get the watermark on videos. Why?

It's most likely because you don't provide a static hostname for the container, or the same hostname you used when "logging in" (getting the license key). Part of the minted license key information is the hostname. As such it's critical to use the same hostname for logging in as when running the container. That's why the examples in this document provide the --hostname argument to docker.
