#!/bin/bash
#SBATCH -A stf007
#SBATCH -J lux_apptainer_pytorch_prebuilt_test
#SBATCH -o logs/%x.%j
#SBATCH -t 00:05:00
#SBATCH -p batch
#SBATCH -N 4
#SBATCH --gpus-per-node=8




module unload xalt
# Get address of head node
ips=`hostname -I`
read -ra arr <<< ${ips}
export MASTER_ADDR=${arr[0]}
echo "MASTER_ADDR=" $MASTER_ADDR

# Needed to bypass MIOpen, Disk I/O Errors
export MIOPEN_USER_DB_PATH="/tmp/my-miopen-cache"
export MIOPEN_CUSTOM_CACHE_DIR=${MIOPEN_USER_DB_PATH}
rm -rf ${MIOPEN_USER_DB_PATH}
mkdir -p ${MIOPEN_USER_DB_PATH}


# these environment variable are needed to bind these libraries from the host into the container.
# These libraries are essential for internode communication. The rocm Pytorch container is not
# distributed with libionic and infiniband libraries, so we need to bind them in from the host into
# the container. RCCL will look for libionic and will try to fall back to other methods if not.
# Unfortunately, the other methods are not supported by Lux, so the run will fail. The below makes
# sure that these libraries are visible to RCCL in the container so that it can properly initialize
# and allow for internode communication.
#export NCCL_DEBUG=INFO
export APPTAINER_BINDPATH=/etc/libibverbs.d
export APPTAINER_CONTAINLIBS=/usr/lib64/libionic.so.1,/usr/lib64/libionic.so.1.1.61,/usr/lib64/libibverbs.so,/usr/lib64/libibverbs.so.1,/usr/lib64/libmlx4.so.1,/usr/lib64/libmlx5.so.1,/usr/lib64/libnl-3.so.200,/usr/lib64/libnl-route-3.so.200
export APPTAINER_CONTAINLIBS=$APPTAINER_CONTAINLIBS,/usr/lib64/libibverbs/libbnxt_re-rdmav59.so,/usr/lib64/libibverbs/libcxgb4-rdmav59.so,/usr/lib64/libibverbs/libefa-rdmav59.so,/usr/lib64/libibverbs/liberdma-rdmav59.so,/usr/lib64/libibverbs/libhfi1verbs-rdmav59.so,/usr/lib64/libibverbs/libhns-rdmav59.so,/usr/lib64/libibverbs/libionic-rdmav59.so,/usr/lib64/libibverbs/libipathverbs-rdmav59.so,/usr/lib64/libibverbs/libirdma-rdmav59.so,/usr/lib64/libibverbs/libmana-rdmav59.so,/usr/lib64/libibverbs/libmlx4-rdmav59.so,/usr/lib64/libibverbs/libmlx5-rdmav59.so,/usr/lib64/libibverbs/libmthca-rdmav59.so,/usr/lib64/libibverbs/libocrdma-rdmav59.so,/usr/lib64/libibverbs/libqedr-rdmav59.so,/usr/lib64/libibverbs/librxe-rdmav59.so,/usr/lib64/libibverbs/libsiw-rdmav59.so,/usr/lib64/libibverbs/libvmw_pvrdma-rdmav59.so

# For this example, there is no real performance difference when using the NIC affinity script vs not
# using it

# without affinity script
echo "without affinity script"
HOME=/tmp srun -l --nodes $SLURM_NNODES --ntasks $((SLURM_NNODES*8)) --tasks-per-node=8 \
    --gpus-per-task 1 --cpus-per-task 1 --gpu-bind=closest --gres-flags=allow-task-sharing \
	apptainer exec --workdir `pwd` ./pytorch_rocm7141.sif ./pyrun.sh #python3 ./microbench_olcf.py --master_addr=$MASTER_ADDR --master_port=3442

# with affinity script
echo "with affinity script"
HOME=/tmp srun -l --nodes $SLURM_NNODES --ntasks $((SLURM_NNODES*8)) --tasks-per-node=8 \
    --gpus-per-task 1 --cpus-per-task 1 --gpu-bind=closest --gres-flags=allow-task-sharing \
 /lustre/orion/stf243/world-shared/xjv/slurm-ucx-affinity-pin \
	apptainer exec --workdir `pwd` ./pytorch_rocm7141.sif ./pyrun.sh # python3 ./microbench_olcf.py --master_addr=$MASTER_ADDR --master_port=3442
