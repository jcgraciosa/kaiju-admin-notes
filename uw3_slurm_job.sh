#!/bin/bash
#
# Slurm job script template for Underworld3 on Kaiju
#
# Usage:
#   sbatch uw3_slurm_job.sh
#   sbatch --nodes=2 --ntasks-per-node=30 uw3_slurm_job.sh
#
# Edit the SBATCH directives and SCRIPT variable below.
#

# ============================================================
# SLURM DIRECTIVES
# ============================================================

#SBATCH --job-name=uw3_job
#SBATCH --output=uw3_%j.out       # %j = job ID
#SBATCH --error=uw3_%j.err
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=30      # 4 nodes x 30 = 120 MPI ranks
#SBATCH --time=01:00:00           # HH:MM:SS wall time limit

# ============================================================
# USER CONFIGURATION — edit this
# ============================================================

# Path to the install script
INSTALL_SCRIPT="${HOME}/install_scripts/uw3_install_kaiju_amr.sh"

# Python script to run
SCRIPT="${HOME}/my_model.py"

# ============================================================
# ENVIRONMENT SETUP
# Loads spack OpenMPI, activates pixi kaiju env, sets PETSC_DIR,
# PYTHONPATH, PMIX_MCA_psec, and OMPI_MCA_btl_tcp_if_include.
# ============================================================

# shellcheck disable=SC1090
source "${INSTALL_SCRIPT}"

# ============================================================
# RUN
# ============================================================

echo "Job started:  $(date)"
echo "Nodes:        ${SLURM_NODELIST}"
echo "MPI ranks:    ${SLURM_NTASKS}"
echo "Script:       ${SCRIPT}"
echo ""

# --mpi=pmix is required for Slurm + OpenMPI on Kaiju
srun --mpi=pmix python3 "${SCRIPT}"

echo ""
echo "Job finished: $(date)"
