# Underworld3 on Kaiju — User Guide

This guide covers how to run Underworld3 (UW3) on the Kaiju cluster, including using the shared installation or setting up your own.

---

## Option A: Use the shared installation (recommended)

The shared installation is available to all users via Lmod. No setup required.

```bash
# List available versions
module avail underworld3

# Load the latest version (replace date with what module avail shows)
module load underworld3/development-12Mar26

# Verify it works
python3 -c "import underworld3 as uw; print(uw.__version__)"
```

That's it. The module sets up Python, MPI, PETSc, and all required environment variables.

---

## Option B: Per-user installation

Use this if you need a custom branch, modified source, or a different version.

### Requirements

- Access to Kaiju head node
- `spack` with `openmpi@4.1.6` available (`spack find openmpi`)

### Install steps

```bash
# Clone the admin scripts
git clone https://github.com/jcgraciosa/kaiju-admin-notes.git ~/install_scripts

# Run the full install (~1 hour, dominated by PETSc build)
source ~/install_scripts/uw3_install_kaiju_amr.sh install
```

### Activate in future sessions

```bash
source ~/install_scripts/uw3_install_kaiju_amr.sh
```

Add this line to your `~/.bashrc` to activate automatically on login.

---

## Running jobs with Slurm

Use `uw3_slurm_job.sh` as a template:

```bash
cp ~/install_scripts/uw3_slurm_job.sh my_job.sh
# Edit my_job.sh: set your script, nodes, tasks, time
sbatch my_job.sh
```

### Key Slurm directives

```bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=30     # CPUs per node (max 104)
#SBATCH --time=02:00:00
```

### Monitor your job

```bash
squeue -u $USER                  # check queue status
tail -f uw3_<jobid>.out          # follow output
scancel <jobid>                  # cancel if needed
```

### Multi-node example (4 nodes, 120 ranks)

```bash
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=30
```

```bash
srun --mpi=pmix -n 120 python3 my_model.py
```

> **Note:** `--mpi=pmix` is required on Kaiju. Do not use `mpirun` in Slurm jobs.

---

## Troubleshooting

### `ModuleNotFoundError: No module named 'underworld3'`

Make sure the module is loaded (Option A) or the install script is sourced (Option B) in your job script — not just in your login shell.

### `MPI errors` or ranks not communicating

Check that `PMIX_MCA_psec=native` and `OMPI_MCA_btl_tcp_if_include=eno1` are set. Both install scripts and the Lmod module set these automatically.

### `numpy.dtype size changed` error

petsc4py was compiled against a different numpy version. Ask the admin to rebuild the shared install, or for per-user installs:
```bash
source ~/install_scripts/uw3_install_kaiju_amr.sh
pip install --force-reinstall "numpy==1.26.4"
CC=mpicc HDF5_MPI=ON HDF5_DIR="${PETSC_DIR}/${PETSC_ARCH}" \
    pip install --no-binary=h5py --force-reinstall --no-deps h5py
```

### Verify your installation

```bash
source ~/install_scripts/uw3_install_kaiju_amr.sh
verify_install
```

---

## Further reading

- [Developer guide (UW3 repo)](https://github.com/underworldcode/underworld3/blob/development/docs/developer/guides/kaiju-cluster-setup.md)
- [Slurm documentation](https://slurm.schedmd.com/documentation.html)
