# Docker Image for ML with PyTorch

![GitHub](https://img.shields.io/github/license/ankur-gupta/ml-pytorch?link=https%3A%2F%2Fgithub.com%2Fankur-gupta%2Fml-pytorch%2Fblob%2Fmain%2FLICENSE)

## Features
### `Dockerfile`
This image has the following installed
* `git`, `rsync`, `ssh`, and other Linux utilities
* [`fish`](https://fishshell.com/) is set to default for the user `neo` (see below)
* `python3` and `pip`
* [Virtualfish](https://github.com/adambrenecki/virtualfish) is available as `vf`
* A `vf` environment called `pytorch` which contains
  * `numpy`, `pandas`, `matplotlib`, `seaborn`
  * `scikit-learn`, `scipy`
  * `torch`, `torchtext`
  * `transformers`, `datasets`, `sentencepiece`
  * `wandb`, `wbutils`
  * `ipython`, `jupyter`
  * `pytest`, `coverage`, and more

Use `pytorch` virtualenv as follows
```shell
# You should be in the (deafult) fish shell (not bash)
vf activate pytorch
ipython
# Run your python code
# Exit ipython
# vf deactivate
```

### User
This image creates a `sudo`-privileged user for you. You should be able to
do everything (including installing packages using `apt-get`) as this user
without having to become `root`.

| Key      | Value        |
|----------|--------------|
| Username | `neo`        |
| Password | `agentsmith` |


## Get the image
### From Docker Hub
```shell
docker pull ankurio/ml-pytorch:latest
docker run -it ankurio/ml-pytorch:latest /usr/bin/fish
```

### Build it yourself
Alternatively, you cna clone the repository and build it yourself. It will take ~10 minutes to build the first time.
```shell
# Clone the repository
git clone git@github.com:ankur-gupta/ml-pytorch.git

# From $REPO_ROOT
cd $REPO_ROOT
docker build . -t ml-pytorch
docker run -it ml-pytorch /usr/bin/fish
```

## Docker tips
### Debugging build errors
A `RUN echo "print something"` line in `Dockerfile` will be useful if you use ["plain progress"](https://stackoverflow.com/a/67548336/4383754)
```shell
docker build . -t ml-pytorch --progress=plain
```

### Clean all containers and images
This does not delete the docker cache. From this
[StackOverflow post](https://stackoverflow.com/a/55499079/4383754).

```shell
# Delete all containers - do this first!
docker rm $(docker ps -a -q)

# Delete all images
docker rmi $(docker images -q)
```
