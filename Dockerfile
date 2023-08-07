FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# This is the user that will execute most of the commands within the docker container.
ARG ML_USER="neo"
ARG ML_USER_PASSWORD="agentsmith"

# Install the things that need root access first.
USER root

# To prevent interactive questions during `apt-get install`
ENV DEBIAN_FRONTEND=noninteractive

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
    software-properties-common \
    openssh-server \
    nginx \
    unzip \
    tree \
    colordiff \
    wdiff \
    most \
    mosh \
    nano \
    curl \
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

# Start NGINX server
RUN service nginx start

# Create $ML_USER non-interactively and add it to sudo group. See
# (1) https://stackoverflow.com/questions/25845538/how-to-use-sudo-inside-a-docker-container
# (2) https://askubuntu.com/questions/7477/how-can-i-add-a-new-user-as-sudoer-using-the-command-line
RUN useradd -m ${ML_USER} \
    && adduser ${ML_USER} sudo \
    && echo ${ML_USER}:${ML_USER_PASSWORD} | chpasswd
RUN usermod -s `which fish` ${ML_USER}

# We will setup environment variables and python packages for the ML_USER instead of `root`.
RUN mkdir -p /home/${ML_USER}/toolbox/bin
RUN mkdir -p /home/${ML_USER}/.git/templates
RUN mkdir -p /home/${ML_USER}/.config/fish/functions
RUN mkdir -p /home/${ML_USER}/.config/fish/conf.d
COPY config.fish /home/${ML_USER}/.config/fish/config.fish
# RUN sudo chown ${ML_USER}:${ML_USER} /home/${ML_USER}/.config/fish/config.fish

# Copy fish history for more productivity
COPY fish_history /home/${ML_USER}/.local/share/fish/fish_history

# Augment path so we can call ipython and jupyter
# Using $HOME would just use the root user. $HOME works with the RUN directive
# which uses the userid of the user in the relevant USER directive. But ENV
# doesn't seem to use this. See https://stackoverflow.com/questions/57226929/dockerfile-docker-directive-to-switch-home-directory
# This is probably why variables set by ENV directive are available to all
# users as mentioned in https://stackoverflow.com/questions/32574429/dockerfile-create-env-variable-that-a-user-can-see
ENV PATH=/home/${ML_USER}/toolbox/bin:$PATH:/home/${ML_USER}/.local/bin

# Setup SSH
RUN mkdir -p /home/${ML_USER}/.ssh
COPY setup-ssh.sh /home/${ML_USER}/setup-ssh.sh
# RUN sudo chown ${ML_USER}:${ML_USER} /home/${ML_USER}/setup-ssh.sh
RUN bash /home/${ML_USER}/setup-ssh.sh

# Install vim packages
RUN rm -rf /home/${ML_USER}/.vim/bundle/Vundle.vim
RUN mkdir -p /home/${ML_USER}/.vim/bundle
RUN git clone https://github.com/VundleVim/Vundle.vim.git /home/${ML_USER}/.vim/bundle/Vundle.vim
RUN echo "Start vim and run :PluginInstall manually"

# Install fishmarks (this creates the .sdirs)
RUN rm -rf /home/${ML_USER}/.fishmarks
RUN git clone http://github.com/techwizrd/fishmarks /home/${ML_USER}/.fishmarks
COPY .sdirs /home/${ML_USER}/.sdirs
# RUN sudo chown ${ML_USER}:${ML_USER} /home/${ML_USER}/.sdirs

# Install Fish SSH agent (so you can store your ssh keys)
# Example usage: ssh-add ~/.ssh/id_rsa_github
RUN rm -rf /home/${ML_USER}/.fish-ssh-agent
RUN git clone https://github.com/tuvistavie/fish-ssh-agent.git /home/${ML_USER}/.fish-ssh-agent
RUN ln -fs /home/${ML_USER}/.fish-ssh-agent/functions/__ssh_agent_is_started.fish /home/${ML_USER}/.config/fish/functions/__ssh_agent_is_started.fish
RUN ln -fs /home/${ML_USER}/.fish-ssh-agent/functions/__ssh_agent_start.fish /home/${ML_USER}/.config/fish/functions/__ssh_agent_start.fish
RUN ls /home/${ML_USER}/.fish-ssh-agent/conf.d/*.fish | xargs -I{} ln -s {} /home/${ML_USER}/.config/fish/conf.d/

# Prepare to install virtualfish
COPY vf-install-env.fish /home/${ML_USER}/vf-install-env.fish
COPY pytorch.requirements.txt /home/${ML_USER}/pytorch.requirements.txt
COPY fish_prompt.fish /home/${ML_USER}/.config/fish/functions/fish_prompt.fish

# Now, switch to our user
RUN sudo chown -R ${ML_USER}:${ML_USER} /home/${ML_USER}
USER ${ML_USER}

# We remove pip cache so docker can store the layer for later reuse.
# Install a pytorch environment using virtualfish
RUN pipx install virtualfish
RUN vf install
RUN mkdir -p /home/${ML_USER}/.virtualenvs
RUN fish /home/${ML_USER}/vf-install-env.fish pytorch && rm -rf /home/${ML_USER}/.cache/pip

# Set the working directory as the home directory of $ML_USER
# Using $HOME would not work and is not a recommended way.
# See https://stackoverflow.com/questions/57226929/dockerfile-docker-directive-to-switch-home-directory
WORKDIR /home/${ML_USER}
