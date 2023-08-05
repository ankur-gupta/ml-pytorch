#!/uxr/bin/env fish

vf new pytorch
pip install --upgrade pip
pip install numpy \
    pandas \
    ipython \
    jupyter \
    ipdb \
    matplotlib \
    seaborn \
    scipy \
    scikit-learn \
    torch \
    torchtext \
    tqdm \
    transformers \
    datasets \
    sentencepiece \
    requests \
    ujson \
    wandb \
    wbutils \
    hatch \
    pytest \
    coverage \
    codecov \
    pytest-cov \
    pytest-mock
vf deactivate
