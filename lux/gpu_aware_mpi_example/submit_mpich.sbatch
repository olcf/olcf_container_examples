#!/bin/bash 
#SBATCH -t00:10:00 
#SBATCH -Astf007
#SBATCH -p batch
#SBATCH -N2
#SBATCH --gpus-per-node 2
#SBATCH -J lux_gpu_aware_mpi_example
#SBATCH -o logs/%x_%j.out


module reset
module unload xalt
module load mpich
module list


# below is necessary to avoid ucx permission denied warning messages
# see https://ciq.com/blog/workaround-for-communication-issue-with-mpi-apps-apptainer-without-setuid
#export UCX_POSIX_USE_PROC_LINK=n



# We are setting this as a convenience that we pass to apptainer's --bind flag. What this does is
# mount the given directories from the host into the container so that they are visible within the
# container. So any application inside the container are able to reach the files in these locations
# on the host. We are binding these specific locations as they are required for the Cray MPICH
# libraries to be visible inside the container and for MPI to work with good performance. The
# application in the container will be able to see and link to the Cray MPICH libraries instead of
# using the MPICH libraries we install in the container.
export APPTAINER_BINDPATH=/sw,/usr/share/libdrm,/var/spool/slurm,${PWD}
export APPTAINER_BINDPATH=/etc/libibverbs.d,$APPTAINER_BINDPATH



# What APPTAINERENV_* does is set that environment variable inside the container environment. 
# For example, if you `export APPTAINERENV_BLAH=foo` before you do an `apptainer (run|exec|shell)`,
# within your container the environment variable BLAH=foo will be set.
# So here, we are setting the value of LD_LIBRARY_PATH inside the container to include the host's 
# MPICH library location (given by $OLCF_MPICH_ROOT). The container will have access to this
# location because we are binding /sw into the container. This will replace any preexisting LD_LIBRARY_PATH
# that might've been defined as part of the container build, so to make sure that the container's
# own LD_LIBRARY_PATH values are not replaced, we include \$LD_LIBRARY_PATH which just passes the
# string '$LD_LIBRARY_PATH' into the container, which then gets evaluated into the container's own
# LD_LIBRARY_PATH value.
export APPTAINERENV_LD_LIBRARY_PATH=$OLCF_MPICH_ROOT/lib:\$LD_LIBRARY_PATH


# APPTAINER_CONTAINLIBS allows you to specify individual libraries from the host that you want
# visible inside the container and added to the LD_LIBRARY_PATH inside the container.
# In this GPU aware MPI example, Some specific libraries from the host's /usr/lib64 need to 
# be visible inside the container for the host's MPICH and UCX libraries (that we are making visible 
# inside the container with the earlier steps) to work.
export APPTAINER_CONTAINLIBS=/usr/lib64/libpmi2.so.0
export APPTAINER_CONTAINLIBS=$APPTAINER_CONTAINLIBS,/usr/lib64/libionic.so.1,/usr/lib64/libionic.so.1.1.61,/usr/lib64/libibverbs.so,/usr/lib64/libibverbs.so.1,/usr/lib64/libmlx4.so.1,/usr/lib64/libmlx5.so.1,/usr/lib64/libnl-3.so.200,/usr/lib64/libnl-route-3.so.200
export APPTAINER_CONTAINLIBS=$APPTAINER_CONTAINLIBS,/usr/lib64/libibverbs/libbnxt_re-rdmav59.so,/usr/lib64/libibverbs/libcxgb4-rdmav59.so,/usr/lib64/libibverbs/libefa-rdmav59.so,/usr/lib64/libibverbs/liberdma-rdmav59.so,/usr/lib64/libibverbs/libhfi1verbs-rdmav59.so,/usr/lib64/libibverbs/libhns-rdmav59.so,/usr/lib64/libibverbs/libionic-rdmav59.so,/usr/lib64/libibverbs/libipathverbs-rdmav59.so,/usr/lib64/libibverbs/libirdma-rdmav59.so,/usr/lib64/libibverbs/libmana-rdmav59.so,/usr/lib64/libibverbs/libmlx4-rdmav59.so,/usr/lib64/libibverbs/libmlx5-rdmav59.so,/usr/lib64/libibverbs/libmthca-rdmav59.so,/usr/lib64/libibverbs/libocrdma-rdmav59.so,/usr/lib64/libibverbs/libqedr-rdmav59.so,/usr/lib64/libibverbs/librxe-rdmav59.so,/usr/lib64/libibverbs/libsiw-rdmav59.so,/usr/lib64/libibverbs/libvmw_pvrdma-rdmav59.so

set -x
# works (for one node, two tasks per node, 1 gpu per task)
srun  -N1 --tasks-per-node 2  --gres-flags=allow-task-sharing --gpus-per-task=1 apptainer --silent exec --workdir `pwd`  ./ubuntumpich501rocm7141_minimal.sif /ping_pong_gpu_aware.exe

# works (for two nodes, 1 task per node, 1 gpu per task)
## without affinity script
srun  -N2 --tasks-per-node 1  --gres-flags=allow-task-sharing --gpus-per-task=1 apptainer --silent exec --workdir `pwd`  ./ubuntumpich501rocm7141_minimal.sif /ping_pong_gpu_aware.exe
## with affinity script
srun  -N2 --tasks-per-node 1  --gres-flags=allow-task-sharing --gpus-per-task=1 \
 /lustre/orion/stf243/world-shared/xjv/slurm-ucx-affinity-pin \
    apptainer --silent exec --workdir `pwd`  ./ubuntumpich501rocm7141_minimal.sif /ping_pong_gpu_aware.exe
