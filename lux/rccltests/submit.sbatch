#!/bin/bash
#SBATCH -t00:10:00
#SBATCH -Astf007
#SBATCH -N2
#SBATCH -q debug
#SBATCH -p batch
#SBATCH -J frontier_apptainer_rccl_tests
#SBATCH -o logs/%x_%j.out


module reset
module load mpich
module unload xalt


export MPICH_GPU_SUPPORT_ENABLED=1
export UCX_POSIX_USE_PROC_LINK=n
export MPICH_SMP_SINGLE_COPY_MODE=NONE

#export NCCL_DEBUG=INFO
export APPTAINER_BIND=/sw,/usr/share/libdrm,/var/spool/slurm,${PWD},${HOME}  
export APPTAINERENV_LD_LIBRARY_PATH=$MPICH_DIR/lib:\$LD_LIBRARY_PATH


# works (for 1 node 8 GPUs exclusive)
srun --mpi=pmi2 -N1 -n4 --gpus-per-task 1 --gres-flags=allow-task-sharing  apptainer exec  rccltests.sif  /rccl-tests/build/all_reduce_perf -b 8 -e 128M -f 2 -g 1
srun --mpi=pmi2 -N1 -n1 --gpus-per-task 8 --gres-flags=allow-task-sharing  apptainer exec  rccltests.sif  /rccl-tests/build/all_reduce_perf -b 8 -e 128M -f 2 -g 8
srun --mpi=pmi2 -N1 -n1 --gpus-per-task 8   apptainer exec  rccltests.sif  /rccl-tests/build/all_reduce_perf -b 8 -e 128M -f 2 -g 8
srun --mpi=pmi2 -N1 -n4 -G8 --gres-flags=allow-task-sharing  apptainer exec  rccltests.sif  /rccl-tests/build/all_reduce_perf -b 8 -e 128M -f 2 -g 2

# fails
## lux006:3114:3253 [0] [FATAL ERROR]: HIP failure: 'invalid device pointer'
srun --mpi=pmi2 -N1 -n4 --gpus-per-task 1 apptainer exec  rccltests.sif  /rccl-tests/build/all_reduce_perf -b 8 -e 128M -f 2 -g 1 
## [ERROR] The number of requested GPUs (8) is greater than the number of GPUs available (2) on node (lux006)
srun --mpi=pmi2 -N1 -n4 --gpus-per-task 2 --gres-flags=allow-task-sharing  apptainer exec  rccltests.sif  /rccl-tests/build/all_reduce_perf -b 8 -e 128M -f 2 -g 2








# old original
#echo "TEST: RCCL MPI Enabled Multi-node test"
#
#echo "RCCL TEST: all_reduce test"
#srun -N2 -n4 apptainer exec --rocm rcclmpich412rocm642.sif  /rccl-tests/build/all_reduce_perf -b 8 -e 128M -f 2 -g 4
#
#echo "RCCL TEST: all_gather test"
#srun -N2 -n4 apptainer exec --rocm rcclmpich412rocm642.sif  /rccl-tests/build/all_gather_perf -b 8 -e 128M -f 2 -g 4
#
#echo "RCCL TEST: alltoall test"
#srun -N2 -n4 apptainer exec --rocm rcclmpich412rocm642.sif  /rccl-tests/build/alltoall_perf -b 8 -e 128M -f 2 -g 4
#
#echo "RCCL TEST: broadcast test"
#srun -N2 -n4 apptainer exec --rocm rcclmpich412rocm642.sif  /rccl-tests/build/broadcast_perf -b 8 -e 128M -f 2 -g 4
#
#echo "RCCL TEST: reduce test"
#srun -N2 -n4 apptainer exec --rocm rcclmpich412rocm642.sif  /rccl-tests/build/reduce_perf -b 8 -e 128M -f 2 -g 4
#
#echo "RCCL TEST: gather test"
#srun -N2 -n4 apptainer exec --rocm rcclmpich412rocm642.sif  /rccl-tests/build/gather_perf -b 8 -e 128M -f 2 -g 4
#
#echo "RCCL TEST: scatter test"
#srun -N2 -n4 apptainer exec --rocm rcclmpich412rocm642.sif  /rccl-tests/build/scatter_perf -b 8 -e 128M -f 2 -g 4
#
#echo "RCCL TEST: sendrecv test"
#srun -N2 -n4 apptainer exec --rocm rcclmpich412rocm642.sif  /rccl-tests/build/sendrecv_perf -b 8 -e 128M -f 2 -g 4
#
#
