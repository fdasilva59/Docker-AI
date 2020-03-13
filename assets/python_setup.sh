#!/bin/bash
set -e

# -----------------------------------------------------------------------------
#                           Detect CUDA version
# -----------------------------------------------------------------------------
#CUDA_PKG_VERSION=10-1=10.1.243-1  # Override
if [ -z CUDA_PKG_VERSION ]; then
    echo "ERROR: CUDA_PKG_VERSION is undefined"
    exit 1
fi

# -----------------------------------------------------------------------------
#                   Customize Installation if needed
# -----------------------------------------------------------------------------
# Note:
#   - Installation intended for GPU setup
#   - python packages to install are defined in the file 'requirements.txt'
#   - RAPIDS is installed via conda (not available from pypy),
#     thus the versions to use are defined below

export PYTHON_VERSION="3.6"
export JAX_VERSION="0.1.39"
export RAPIDS_VERSION="0.12"

export PYPY_BASE_URL="https://bitbucket.org/pypy/pypy/downloads"
export PYPY_FILE="pypy3.6-v7.3.0-linux64.tar.bz2"
export PYPY_SHA256="d3d549e8f43de820ac3385b698b83fa59b4d7dd6cf3fe34c115f731e26ad8856  pypy3.6-v7.3.0-linux64.tar.bz2"


# *** Don't Modify below ***
export PY="$(echo $PYTHON_VERSION | sed -s 's/\.//g')"
export PYPY=$(echo $PYPY_FILE | sed -e 's/.tar.bz2//g')
export CUDA_TOOLKIT="$(echo $CUDA_PKG_VERSION | cut -d "=" -f1 | sed -s 's/-/./g')"
export CUDA_VERSION="cuda$(echo $CUDA_PKG_VERSION | cut -d "=" -f1 | sed -s 's/-//g')"

USER_NAME="$(id -n -u)"
ENV_NAME="docker-ai"
INSTALL_DIR="/home/$USER_NAME"
mkdir -p $INSTALL_DIR  # Just in case...

echo "-----------------------------------------------------------"
echo "Executing python_setup.sh"
echo ""
echo "[PYTHON SETUP][INFO] USER_NAME=$USER_NAME"
echo "[PYTHON SETUP][INFO] INSTALL_DIR=$INSTALL_DIR"
echo "[PYTHON SETUP][INFO] ENV_NAME=$ENV_NAME"
echo "[PYTHON SETUP][INFO] CUDA_PKG_VERSION=$CUDA_PKG_VERSION"
echo "[PYTHON SETUP][INFO]    inferred CUDA_TOOLKIT=$CUDA_TOOLKIT"
echo "[PYTHON SETUP][INFO]    inferred CUDA_VERSION=$CUDA_VERSION"
echo "[PYTHON SETUP][INFO] PYTHON_VERSION=$PYTHON_VERSION"
echo "-----------------------------------------------------------"

# -----------------------------------------------------------------------------
#                               Conda Setup
# -----------------------------------------------------------------------------

# Download and Install Mini cCnda
rm -rf $INSTALL_DIR/conda
rm -rf $INSTALL_DIR/.conda
curl -s -o /tmp/Miniconda3-latest-Linux-x86_64.sh https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod u+x /tmp/Miniconda3-latest-Linux-x86_64.sh
/tmp/Miniconda3-latest-Linux-x86_64.sh -f -b -p $INSTALL_DIR/conda/

# Patch Conda to avoid 'Maximum Recursion Error'
echo "export PATH=$PATH:$INSTALL_DIR/conda/bin" >> /home/$USER_NAME/.profile
/home/$USER_NAME/patch_conda.sh

# Create the conda environment
$INSTALL_DIR/conda/bin/conda create -y -n $ENV_NAME python=$PYTHON_VERSION
echo "source activate $ENV_NAME" >> /home/$USER_NAME/.bashrc


# -----------------------------------------------------------------------------
#       Python Setup : conda install (first) followed by pip installs
# -----------------------------------------------------------------------------
source .profile
source .bashrc

# Install RAPIDS from conda (not yet available from pypi repository)
conda install -c rapidsai -c nvidia -c conda-forge -c defaults rapids=$RAPIDS_VERSION python=$PYTHON_VERSION cudatoolkit=$CUDA_TOOLKIT
conda install nodejs

# Install Python packages as defined in requirements.txt and constraints.txt
pip install --ignore-installed -r requirements.txt -c constraints.txt

# If available, make the Python TPU Edge libraries available to the conda virtual environment
if [ -d "/usr/lib/python3/dist-packages/edgetpu" ]; then
   echo "Make available the Python TPU Edge libraries in the conda virtual environment"
   cp -R /usr/lib/python3/dist-packages/edgetpu* /home/$USER_NAME/conda/envs/$ENV_NAME/lib/python$PYTHON_VERSION/
fi

# Workaround : Make the Nvidia NVVM libdevice library available to Jax
# (See https://github.com/google/jax/issues/989#issuecomment-511632574 )
if [ -f ~/conda/envs/$ENV_NAME/lib/libdevice.10.bc ]; then
   echo "Make available the NVVM libdevice library for Jax"
    mkdir -p ~/xla/nvvm/libdevice
    ln -P ~/conda/envs/$ENV_NAME/lib/libdevice.10.bc ~/xla/nvvm/libdevice/libdevice.10.bc
    echo "export XLA_FLAGS='--xla_gpu_cuda_data_dir=/home/$USER_NAME/xla'" >> /home/$USER_NAME/.bashrc
fi

# Enable Nvidia Dashboard in Jupyter Lab
# Current ISSUE: "Not Supported error on systems without NVLink" in Jupyter logs (https://github.com/rapidsai/jupyterlab-nvdashboard/issues/28)
if pip list | grep "jupyterlab-nvdashboard"; then
    echo "Enabling Nvidia Dashboard in Jupyter Lab"
    jupyter labextension install jupyterlab-nvdashboard
fi

# Export docker-ai installed Python packages list
conda list --export > /home/$USER_NAME/requirements.frozen


# -----------------------------------------------------------------------------
#          Install PyPy
# -----------------------------------------------------------------------------
echo $PYPY_SHA256 > ./$PYPY_FILE.sha256
wget -q -O ./$PYPY_FILE $PYPY_BASE_URL/$PYPY_FILE
if ! sha256sum -c --status ./$PYPY_FILE.sha256 ; then
  echo "Checksum failed for $PYPY_FILE"
  exit 1
else
  echo "Installing pypy..."
  tar -C $INSTALL_DIR/ -xvf $PYPY_FILE
  if ! grep -q pypy /home/$USER_NAME/.bashrc; then
      echo "Adding pypy to path..."
      echo "PATH=$PATH:$INSTALL_DIR/$PYPY/bin" >> /home/$USER_NAME/.bashrc
  fi
fi
rm ./$PYPY_FILE ./$PYPY_FILE.sha256

# -----------------------------------------------------------------------------
#                          Post Install Cleaning
# -----------------------------------------------------------------------------
conda clean -y --tarballs
rm -rf /tmp/.[!.]* /tmp/* /home/$USER_NAME/.cache/pip
