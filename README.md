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

```sh
docker run --rm -ti --gpus all -hostname $HOSTNAME --user $UID:$GID \
-v $PWD/models:/models \
-v $PWD/auth/auth.tpz:/opt/TopazVideoAIBETA/models/auth.tpz \
-v $PWD:/workspace topaz-vai \
ffmpeg -i clip-from-host.mp4 ...
```

### Customizing which information to mount where

If you want to separate the workspace from the models and license key, just mount those other directories instead.
In my personal setup, I've got the models in /tmp/models on the host, and the license key in my home directory, so the command I use to run the container is instead:

```sh
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

## Build different versions of TVAI
To build a container with a different version than the default, you need to specify two things:

1. The version of TVAI to use.
2. The SHA256 hash of the deb file for that version as obtained from Topaz.

Example:
```sh
$ docker build --tag topaz-vai:3390b \
  --build-arg "VAI_VERSION=3.3.9.0.b" \
  --build-arg "VAI_SHA2=a7de7730e039a8542280c65734143b6382c72eaa81e6fd8c0f23432ca13c8ba2" \
  .
```

Here are a couple of versions with their corresponding hashes, so you don't have to download the debs yourself redundantly just to compute the hashes:

```
a7de7730e039a8542280c65734143b6382c72eaa81e6fd8c0f23432ca13c8ba2  TopazVideoAIBeta_3.3.9.0.b_amd64.deb
b0deb4c919b6543879070cada170be2df9740db0a1be9fb16630151e005a8701  TopazVideoAIBeta_3.4.3.0.b-1_amd64.deb
607e1b9ad497a353f5efe901a1640a7fe1f9dc7445bbad16f86bf0969f5b9083  TopazVideoAIBeta_3.4.4.0.b_amd64.deb
2ce5c76f07e97d5c16d483644d1fae276061bc39a3a5c8220a262495876efb57  TopazVideoAIBeta_3.5.1.0.b_amd64.deb
27382ab6c3f3d0c81f3f18f3f7eacf760f740561ef12b567bd74ff73273f8392  TopazVideoAIBeta_3.5.2.0.b_amd64.deb
4c60c46ce9c0f76314319e304d08c646529aeb554a95ceb33b76f09044f4655a  TopazVideoAIBeta_3.5.3.0.b_amd64.deb
4d3971be331fe12fcd0e11e1e4666ef0ff3868cf03c3262338fc68b263afebf2  TopazVideoAIBeta_4.0.3.2.b_amd64.deb
5bef82e774b70f74f040958e6516d703fab839f19a6bab5ccf72a1e1fc4ccae3  TopazVideoAIBeta_4.0.5.0.b_amd64.deb
e8567bf60e1dec961cf4b471cd93c7ac63629ab49e97aac5b9e561409224d990  TopazVideoAIBeta_4.0.7.0.b_amd64.deb
258627001c685aa9feed34a013b48003456f5fc5239151d6a5d5440b51fc795e  TopazVideoAIBeta_5.0.3.1.b_amd64.deb
```

_This set of debs were those I could find in the Beta release notes that had binaries published for ubuntu, as of 2025-01-02. Additionally, since late 2024, Topaz has started publishing the hashes along with the deb packages (thanks Gregory), so you can find the hash along with the published version in the community forum's release notes without having to download the package yourself just to calculate the hash. For instance, [this](https://community.topazlabs.com/t/topaz-video-ai-linux-beta-v5-0-3-0-b/) release note._

If you want to use a version which isn't on the list above, then these are the steps to produce the hash for that version, using 3.3.9.0.b as an example:
```sh
$ curl -LO https://downloads.topazlabs.com/deploy/TopazVideoAIBeta/3.3.9.0.b/TopazVideoAIBeta_3.3.9.0.b_amd64.deb

$ sha256sum TopazVideoAIBeta_3.3.9.0.b_amd64.deb
a7de7730e039a8542280c65734143b6382c72eaa81e6fd8c0f23432ca13c8ba2  TopazVideoAIBeta_3.3.9.0.b_amd64.deb

$ rm TopazVideoAIBeta_3.3.9.0.b_amd64.deb  # was only needed to create the hash
```

### Streamlining building and using different versions

Building and testing different versions of VAI is a common task, and sort of the whole point of this repository. As such that process has been streamlined using the provided Makefile.

```sh
$ make build VAI_VERSION=4.0.7.0.b \
             VAI_SHA2=e8567bf60e1dec961cf4b471cd93c7ac63629ab49e97aac5b9e561409224d990
```
will create the necessary docker build commands and give your container a tag derived from the VAI version number you provided. In the example, it will run these commands for you.

```sh
docker build -t topaz-vai \
--build-arg "VAI_VERSION=4.0.7.0.b" \
--build-arg "VAI_SHA2=e8567bf60e1dec961cf4b471cd93c7ac63629ab49e97aac5b9e561409224d990" .
docker tag topaz-vai topaz-vai:4070b
```

Do note that two docker tags are always produced; one being tagged with the specific VAI version, so you can refer back to older builds you may have, in order to compare the results between them, track down bugs or _whatever_. The other tag assigned is `:latest`, and is what the other make targets like `login`, `test` and `benchmark` use. Consequently those targets will use the latest container you built. 

If you want to use those targets with a different version, then just set the `latest` tag to some of your other VAI builds. E.g. `docker tag topaz-vai:3390b topaz-vai:latest`

## FAQ

### Q1: I have a headless setup, will this work in that context ?

Yes. This project was specifically created to facilitate that use case.
All you need is a valid `auth.tpz` file mounted or copied to the model's directory in the container: `/opt/TopazVideoAIBETA/models/auth.tpz`

In fact, if you don't mind a watermark, you don't even need the license file. This is great if you just want to see if the software works on different machines, or benchmark performance between different hardware. In such cases the watermark doesn't matter, so you can run the container without any mounting or configuration needed. E.g. `docker run topaz-vai ffmpeg -h filter=tvai_up` to view the documentation of some topaz filter (enhancement model configuration).

### Q2: Will I ever need to refresh the auth.tpz file ?
Yes. The file is only valid for a limited time. How long exactly, Topaz has not disclosed (to my knowledge).

If you run into a problem where the watermark suddenly starts being introduced, it may be because the license file expired. Just redo step 1 in the usage instruction to get a refreshed license file.

### Q3: The `make test` doesn't run the encoding pipeline, just exits, why ?

Use version `3.5.1.0.b` or later.

_Topaz seems to have [fixed the issue](https://community.topazlabs.com/t/tvai-engine-crashes-4-5-times-on-linux-3-4-4-0-b/52485/13). I've confirmed that version as well as the latest of this writing now both launch with 100% successrate on my 3090. The below is historical but may still be relevant in case of future release regressions._

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

One of three reasons:
* A: Hostname mismatch, where the license was issued for one machine (hostname) but you're running the container on another (different hostname)
* B: The license file itself has expired.
* C: You're not entitled to use that specific version of TVAI.

In case of A, ensure you're using the same  hostname for the container as you used during the login step (getting the license key). Part of the minted license key information is the hostname. As such it's critical to use the same hostname for logging in as when running the container. That's why the examples in this document provide the --hostname argument to docker. The Makefile always uses the hostname of your linux machine, so this potential mismatch shouldn't happen when using the make targets. It _may_ however happen if you launch the container on your own using docker, so just pay attention to this detail in such cases.

In case of B, just redo the login step to get a refreshed license file from Topaz.

Finally, in case of C, it could be that you are using a version of TVAI that your license doesn't cover. In particular, if you've cancelled your renewal at say before v5 was released, then it means you're only entitled to use versions 4.x and below. This is currently my exact situation. To verify if this is the case run `make test` and look at the ffmpeg output.

A successful license pass will contain these lines:
```
INFO:  Checking for authentication at /opt/TopazVideoAIBETA/models/auth.tpz
INFO:  Successfully authenticated for user: <your email address>
```
_using a 3.x or 4.x version in my case._

An unsuccessful, such as when you're using a version you're not entitled to will instead show:
```
INFO:  Checking for authentication at /opt/TopazVideoAIBETA/models/auth.tpz
CRITICAL:  Problems with unzipping file: Unable to get info on first file in zip archive
CRITICAL:  Invalid auth file
```
_using v5 in my case, which my license doesn't cover._

So just use a version that you are entitled to, and the watermark should go away.

### Q8: Why the hassle with the deb hashes?

Security. Specifically, in order to ensure that the Topaz code you bake into your image is in fact what you expect. It may be argued as a bit redundant, since the encrypted SSL (TLS/HTTPS) connection _should_ ensure secure communication between your machine and Topaz, and the DEB packages themselves usually also have some cryptographic verifications, that might be deemed sufficient. But I'm security paranoid, so there are two potential attacks and one accidental case using explicit hashing avoids; First, TLS is known to be insufficient to guard against nation state actors as they issue their own CA certificates and can MITM any traffic at their discretion when the public CA certificate list in browsers and linux distribution is relied on. Second, whomever controls Topaz's storage or CDN traffic could manipulate the data before it's sent to you, not to mention a potentially "rogue" employee. Third, to protect yourself against yourself; E.g. thinking you'd baked a certain version, but in fact it was another. Akin to the "please retype your password" check on a website signup.