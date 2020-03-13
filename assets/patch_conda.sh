#!/bin/bash
set -e

# -----------------------------------------------------------------------------
#            This script allows to patch conda to avoid the
#        'Maximum Recursion Error" when downloading python package
# -----------------------------------------------------------------------------
# Note:
#   - If you later update conda, you may need to reapply the patch
#     (Rebuilding the Docker image is probably a better option)

source .profile
source .bashrc
conda_dir=$(which conda | awk '{sub(/conda.*/ , "conda"); print}')
conda_files=$(find $conda_dir -type f -name "download.py" -print | grep "conda\/gateways")

for f in $conda_files
do
    if ! grep -q "sys.setrecursionlimit(100000)" $f ; then
      printf "[PATCH] Applying patch to avoid 'Maximum Recursion Error' in \n $f \n"
      sed -i -e 's/import sys/import sys\nsys.setrecursionlimit(100000)/g' $f
    else
      printf "[INFO] Patch to avoid 'Maximum Recursion Error' is already present in \n $f \n"
    fi
done
