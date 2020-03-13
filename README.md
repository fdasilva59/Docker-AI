# AI-Docker

**Easily build a customizable, ready to use Docker Image for some AI/Data Science/Deep Learning experiments.**

## Goal

The purpose of this project is :
- to provide a Docker template to build a Docker GPU Image that contains all the AI tools that I need/use to *experiments* on projects.
- to make it easy to customize the packages to be installed

**IMPORTANT** : Have in mind that this project is designed for my own AI/Deep Learning experiments:

- **This is my experimental setup to experiments on various topics**
- The resulting docker image is not intended to be used in production environment
- Instead, the resulting docker image is expected to be used on a local workstation (aka "AI/Deep LEarning DevBox")
- The docker image is intended for systems with Nvidia GPU only.
- My goal with this image is to have all the frameworks and libraries  I use or want to try, to be available to me in a single Docker Image. **As a consequence this docker image is HUGE (> 15GB)** You may want to customize the list of packages to be installed.
- With that kind of image, I can easily experiment on different projects, switch between different approaches, frameworks or topics

### Docker Image receipt

- Based on an Nvidia CUDA 10.1 cuDNN 7 “devel” Ubuntu image
   - CUDA 10.1 cuDNN 7 for Tensorflow 2.1 (at the time of writing)
   - “devel”  for jax which makes use of ptxas binary…
- Update/Upgrade the APT packages
- Install all APT packages listed in `requirements.system`
- Install Mini Conda (+ apply a patch to avoid “Maximum Recursion Error”)
- Import in the Docker Image some configuration files (for bash, jupyter… and the python `requirements.txt` and `constraints.txt`)
- Import the `python-setup.sh` script and execute it
  - Create a Python 3 virtual environment
  - Install all the pip packages listed in `requirements.txt` and following the versions constraints in `constraints.txt`
  - “Little bit of magic” to make the Coral TPU Edge and Jax works in the python virtual environment
  - Install pypy

**Note:**
  - The `python-setup.sh` execution is done as the “user” and not ‘root’, such that the user UID and GID from the host can be mapped inside the container (This avoids ownership issues with file creates in the docker container and saved in a Docker shared volume on the host)

  - As usually with python when you try to install several frameworks in the same environment, you may face some python packages conflicts/constraints (Not everything is possible!)

### Docker Image contents

In my default current configuration, this Dockerfile will build an image containing the latest versions of the following frameworks:

- Tensorflow (>2.1)
- Tensorflow Lite with Coral TPU Edge support
- Pytorch (>1.4) & Fast.ai
- Rapids
- Jax

Lots of libraries are included, for example for Visualization (bokeh, altair/streamlit, …), NLP (spacy, gensim, nltk, …), or Deep Reinforcement Learning (Gym…)...

### How to use

1. Optional: Customize the Docker Image
- `assets/requirements.system` (APT packages list to install)
- `assets/requirements.txt` (PIP packages list to install)
- `assets/constraints.txt` (PIP packages constraints to enforce)
- (and if needed, modify `Dockerfile`, `assets/python_setup.sh`)

2. Build the Image

```
docker build -t docker-ai .
```

3. launch a Docker container:

```
docker run --runtime=nvidia --rm -it -p 8888:8888 -p 6006:6006 -v <HOST_PERSISTENT_STORAGE_PATH>:/home/docker-ai/projects -u docker-ai docker-ai
```
Once in the container, you can
- launch `jupyter lab`
- access Jupyter Lab on your host at the following URL: http://127.0.0.1:8888
- access Tensorboard on your host at the following URL: http://127.0.0.1:6006

