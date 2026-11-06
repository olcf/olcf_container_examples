#!/bin/bash
#SBATCH -A stf007
#SBATCH -J lux_apptainer_pytorch_prebuilt_test
#SBATCH -o logs/%x.%j
#SBATCH -t 00:05:00
#SBATCH -p batch
#SBATCH -N 4
#SBATCH --gpus-per-node=8


module reset


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


# uncomment the below line if you want debug output
# export NCCL_DEBUG=INFO

# For this example, there is no real performance difference when using the NIC affinity script vs not
# using it

# without affinity script
echo "without affinity script"
HOME=/tmp srun -l --nodes $SLURM_NNODES --ntasks $((SLURM_NNODES*8)) --tasks-per-node=8 \
    --gpus-per-task 1 --cpus-per-task 1 --gpu-bind=closest --gres-flags=allow-task-sharing \
	apptainer exec --workdir `pwd` ./pytorch_rocm7141_rdmacore.sif ./pyrun.sh #python3 ./microbench_olcf.py --master_addr=$MASTER_ADDR --master_port=3442

# with affinity script
echo "with affinity script"
HOME=/tmp srun -l --nodes $SLURM_NNODES --ntasks $((SLURM_NNODES*8)) --tasks-per-node=8 \
    --gpus-per-task 1 --cpus-per-task 1 --gpu-bind=closest --gres-flags=allow-task-sharing \
 /lustre/orion/stf243/world-shared/xjv/slurm-ucx-affinity-pin \
	apptainer exec --workdir `pwd` ./pytorch_rocm7141_rdmacore.sif ./pyrun.sh # python3 ./microbench_olcf.py --master_addr=$MASTER_ADDR --master_port=3442
