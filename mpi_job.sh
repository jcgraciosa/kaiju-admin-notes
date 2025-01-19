#!/bin/bash

#SBATCH --job-name=mpi_test
#SBATCH --output=mpi_test.out
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=30
#SBATCH --time=00:10:00

export PMIX_MCA_psec=native
export OMPI_MCA_btl_tcp_if_include=eno1
#spack load openmpi@4.1.6
source /home/juan/install_scripts/uw3_install_kaiju_run.sh

# --mpi=pmix is necessary
#srun --mpi=pmix ./mpi_hello
#srun --mpi=pmix python3 hello_world.py
#srun --mpi=pmix python petsc4py_poisson_test.py
srun --mpi=pmix python poisson_uw3.py
