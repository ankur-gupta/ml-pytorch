FROM ubuntu:mantic

# This is the user that will execute most of the commands within the docker container.
ARG ML_USER="neo"
ARG ML_USER_PASSWORD="agentsmith"

# Install the things that need root access first.
USER root

# We clean up apt cache to reduce image size as mentioned here:
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run
RUN apt-get update \
    && apt-get install -y \
        sudo \
        rsync \
        unzip \
        nano \
        wget \
        man \
        tree \
        vim-tiny \
        iputils-ping \
        ssh \
        openjdk-8-jdk \
        python3 \
        python3-dev \
        python3-pip \
 && rm -rf /var/lib/apt/lists/*


RUN echo python3 --version

# Create $ML_USER non-interactively and add it to sudo group. See
# (1) https://stackoverflow.com/questions/25845538/how-to-use-sudo-inside-a-docker-container
# (2) https://askubuntu.com/questions/7477/how-can-i-add-a-new-user-as-sudoer-using-the-command-line
RUN useradd -m $ML_USER \
    && adduser $ML_USER sudo \
    && echo $ML_USER:$ML_USER_PASSWORD | chpasswd \

# We will setup environment variables and python packages for the ML_USER instead of `root`.
USER $ML_USER

# Note that there is no `pip` executable; use `pip3`.
# Install the common packages we may need. We should be able to install more packages by running
# `pip3 install --user <package-name>` within the container later on, if needed.
# We remove pip cache so docker can store the layer for later reuse.
RUN pip3 install --user \
    numpy \
    pandas \
    six \
    ipython \
    jupyter \
    matplotlib \
    seaborn \
    scipy \
    scikit-learn \
  && rm -rf /home/ML_USER/.cache/pip \

# Augment path so we can call ipython and jupyter
# Using $HOME would just use the root user. $HOME works with the RUN directive
# which uses the userid of the user in the relevant USER directive. But ENV
# doesn't seem to use this. See https://stackoverflow.com/questions/57226929/dockerfile-docker-directive-to-switch-home-directory
# This is probably why variables set by ENV directive are available to all
# users as mentioned in https://stackoverflow.com/questions/32574429/dockerfile-create-env-variable-that-a-user-can-see
ENV PATH=$PATH:/home/$ML_USER/.local/bin

# Set the working directory as the home directory of $ML_USER
# Using $HOME would not work and is not a recommended way.
# See https://stackoverflow.com/questions/57226929/dockerfile-docker-directive-to-switch-home-directory
WORKDIR /home/$ML_USER

# Create workspace directory
RUN mkdir /workspace

