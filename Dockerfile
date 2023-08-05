FROM ubuntu:mantic

# This is the user that will execute most of the commands within the docker container.
ARG ML_USER="neo"
ARG ML_USER_PASSWORD="agentsmith"

# Install the things that need root access first.
USER root

# Create workspace directory
RUN mkdir /workspace

# We clean up apt cache to reduce image size as mentioned here:
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run
RUN apt-get update \
    && apt-get install -y \
    sudo \
    rsync \
    ssh \
    git \
    git-extras \
    unzip \
    tree \
    colordiff \
    wdiff \
    most \
    mosh \
    nano \
    wget \
    man \
    iputils-ping \
    python3-pip \
    python3-venv \
    python3-dev \
    pipx \
    fish \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# You need docker build . -t image_name --progress=plain
# (from https://stackoverflow.com/a/67548336/4383754)
RUN echo python3 --version

# Create $ML_USER non-interactively and add it to sudo group. See
# (1) https://stackoverflow.com/questions/25845538/how-to-use-sudo-inside-a-docker-container
# (2) https://askubuntu.com/questions/7477/how-can-i-add-a-new-user-as-sudoer-using-the-command-line
RUN useradd -m ${ML_USER} \
    && adduser ${ML_USER} sudo \
    && echo ${ML_USER}:${ML_USER_PASSWORD} | chpasswd
RUN usermod -s `which fish` ${ML_USER}

# We will setup environment variables and python packages for the ML_USER instead of `root`.
USER ${ML_USER}
RUN mkdir -p /home/${ML_USER}/toolbox/bin
RUN mkdir -p /home/${ML_USER}/.git/templates
RUN mkdir -p /home/${ML_USER}/.config/fish/functions

# Augment path so we can call ipython and jupyter
# Using $HOME would just use the root user. $HOME works with the RUN directive
# which uses the userid of the user in the relevant USER directive. But ENV
# doesn't seem to use this. See https://stackoverflow.com/questions/57226929/dockerfile-docker-directive-to-switch-home-directory
# This is probably why variables set by ENV directive are available to all
# users as mentioned in https://stackoverflow.com/questions/32574429/dockerfile-create-env-variable-that-a-user-can-see
ENV PATH=/home/${ML_USER}/toolbox/bin:$PATH:/home/${ML_USER}/.local/bin

# Install vim packages
# For vim packages
RUN rm -rf /home/${ML_USER}/.vim/bundle/Vundle.vim
RUN mkdir -p /home/${ML_USER}/.vim/bundle
RUN git clone https://github.com/VundleVim/Vundle.vim.git /home/${ML_USER}/.vim/bundle/Vundle.vim
RUN echo "Start vim and run :PluginInstall manually"

# Install fishmarks (this creates the .sdirs)
RUN rm -rf /home/${ML_USER}/.fishmarks
RUN git clone http://github.com/techwizrd/fishmarks /home/${ML_USER}/.fishmarks

# Install Fish SSH agent (so you can store your ssh keys)
# Example usage: ssh-add ~/.ssh/id_rsa_github
RUN rm -rf /home/${ML_USER}/.fish-ssh-agent
RUN git clone https://github.com/tuvistavie/fish-ssh-agent.git /home/${ML_USER}/.fish-ssh-agent
RUN mkdir -p /home/${ML_USER}/.config/fish/conf.d

RUN pipx install virtualfish
RUN vf install
RUN mkdir -p /home/${ML_USER}/.config/fish/functions
COPY fish_prompt.fish /home/${ML_USER}/.config/fish/functions/fish_prompt.fish
RUN mkdir -p /home/${ML_USER}/.virtualenvs

# Install a pytorch environment using virtualfish
COPY pytorch.fish /home/${ML_USER}/pytorch.fish
RUN fish /home/${ML_USER}/pytorch.fish

# Set the working directory as the home directory of $ML_USER
# Using $HOME would not work and is not a recommended way.
# See https://stackoverflow.com/questions/57226929/dockerfile-docker-directive-to-switch-home-directory
WORKDIR /home/${ML_USER}
