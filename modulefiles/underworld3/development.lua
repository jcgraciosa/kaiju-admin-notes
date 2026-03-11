-- Underworld3 with AMR support
-- Shared install: pixi (kaiju env) + spack OpenMPI + PETSc + petsc4py
--
-- Install path: /opt/cluster/software/underworld3
-- Usage:        module load underworld3/development
--
-- Admin: if spack OpenMPI is rebuilt (hash changes), update mpi_root below.

local version  = "development"
local base     = "/opt/cluster/software/underworld3"
local petsc    = base .. "/petsc-custom/petsc"
local arch     = "petsc-4-uw"
local mpi_root = "/opt/cluster/spack/opt/spack/linux-rocky8-skylake_avx512/gcc-8.5.0/openmpi-4.1.6-ticvlnexxf22yptz7rw37fqhgbijeknn"

whatis("Name:        Underworld3")
whatis("Version:     " .. version)
whatis("Description: Geodynamics simulation framework with AMR support")
whatis("URL:         https://github.com/underworldcode/underworld3")

help([[
Underworld3 geodynamics framework with AMR support.

To use:
  module load underworld3/development
  python3 -c "import underworld3 as uw; print(uw.__version__)"

To run with MPI:
  mpirun -n 4 python3 your_script.py
  srun --mpi=pmix -n 120 python3 your_script.py   # via Slurm

For your own installation, see:
  /opt/cluster/software/underworld3/README_install.md
]])

-- Spack OpenMPI
prepend_path("PATH",            mpi_root .. "/bin")
prepend_path("LD_LIBRARY_PATH", mpi_root .. "/lib")

-- pixi kaiju environment (Python, numpy, sympy, scipy, gmsh, etc.)
prepend_path("PATH",            base .. "/.pixi/envs/kaiju/bin")
prepend_path("LD_LIBRARY_PATH", base .. "/.pixi/envs/kaiju/lib")

-- PETSc + petsc4py + h5py + mpi4py (source-built against spack OpenMPI)
prepend_path("LD_LIBRARY_PATH", petsc .. "/" .. arch .. "/lib")
prepend_path("PYTHONPATH",      petsc .. "/" .. arch .. "/lib")

-- PETSc env vars (used by some UW3 utilities)
setenv("PETSC_DIR",  petsc)
setenv("PETSC_ARCH", arch)

-- Required for Slurm + PMIx + OpenMPI on Kaiju
setenv("PMIX_MCA_psec",               "native")
setenv("OMPI_MCA_btl_tcp_if_include", "eno1")
