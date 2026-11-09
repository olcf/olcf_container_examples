# Pytorch MNIST example using DistributedDataParallel

Pytorch examples borrowed from: [PrincetonUniversity/multi_gpu_training](https://github.com/PrincetonUniversity/multi_gpu_training/tree/main)
and from the OLCF docs.

To switch between running the two available examples `./multinode_olcf_mnist_princeton_nompi4py.py`
and `./microbench_olcf.py`, uncomment the appropriate line in the `pyrun.sh`.

AMD maintains several ML and AI containers on DockerHub at https://hub.docker.com/u/rocm . Here we
show how to run a Pytorch example using their Pytorch container.


To pull the pytorch container from the official ROCm container registry

```
apptainer build pytorch_rocm7141.sif docker://docker.io/rocm/pytorch:rocm7.14.1_ubuntu24.04_py3.13_pytorch_release_2.12.0
```

**We need to use a container with Rocm 7.14 since we know that the RCCL version in this release properly supports the
AMD NICs on Lux**


Download the MNIST dataset first before submitting the job (not required if you are running
`./microbench_olcf.py`):
```
./downloadmnist.sh
```

Submit the job with: 
```
sbatch submit.sbatch
```

You will note that the submit script sets up environment variables that binds in a large number of
libraries from the host into the container. This is necessary because Pytorch uses RCCL, which looks
for libionic for communication. It will fail without these binds. If you want to avoid these binds,
you need to build rdma-core v61 from source in the container so that it matches what is installed on
Lux, and you need to build a patched version of libionic obtained from AMD. You can see this in the
`./pytorch_rocm7141_rdmacore.def` file. To build this image:

```
apptainer build ./pytorch_rocm7141_rdmacore.sif ./pytorch_rocm7141_rdmacore.def
```

And then to run it, submit `submit_nobinds.sbatch` which does not set up those environment
variables.

```
sbatch submit_nobinds.sbatch`
```
