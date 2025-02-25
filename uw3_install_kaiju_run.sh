#!/bin/zsh

usage="
Usage:
  A script to install and run an Underworld software stack.
  Change the directories accordingly when line comment says '# user_input'
  Some of the additional modules are loaded through spack.

** To install **
Review script details: modules, paths, repository urls / branches etc.
 $ source <this_script_name>
 $ install_python_dependencies
 $ install_petsc
 $ install_h5py
 $ install_underworld3

** To run **
source this file to open the environment
"

while getopts ':h' option; do
  case "$option" in
    h) echo "$usage"
       # safe script exit for sourced script
       (return 0 2>/dev/null) && return 0 || exit 0
       ;;
    \?) # incorrect options
       echo "Error: Incorrect options"
       echo "$usage"
       (return 0 2>/dev/null) && return 0 || exit 0
       ;;
  esac
done

# currently assumes that spack will only have one python for each major version
PYVER="3.12"
spack load python@${PYVER} openmpi@4.1.6

export OPENBLAS_NUM_THREADS=1 # not sure if this is needed
export OMPI_MCA_io=ompio      # not sure if this is needed

GIT_COMMAND="git clone --branch development --depth 1 https://github.com/underworldcode/underworld3.git"
GIT_COMMAND_H5PY="git clone https://github.com/h5py/h5py.git"

# need to edit especially the USER_HOME
export USER_NAME=juan                                   # user_input
export USER_HOME=/home/${USER_NAME}                     # user_input
export INSTALL_NAME=uw3-venv-run                        # user_input
export UW3_NAME=uw3-run

export INSTALL_PATH=$USER_HOME/uw3-local-installation

export ENV_PATH=${INSTALL_PATH}/${INSTALL_NAME}
export PKG_PATH=${INSTALL_PATH}/manual-install-pkg          # user_input
export PETSC_INSTALL=$PKG_PATH/petsc                        # user_input

export CDIR=$PWD

install_petsc(){

		source ${ENV_PATH}/bin/activate
		mkdir -p $PETSC_INSTALL
		mkdir -p $INSTALL_PATH/tmp/src
		cd $INSTALL_PATH/tmp/src
		PETSC_VERSION="v3.22.2"
        git clone --branch $PETSC_VERSION --depth 1 https://gitlab.com/petsc/petsc.git
        cd petsc
		#PETSC_VERSION="main"
		#wget https://gitlab.com/petsc/petsc/-/archive/main/petsc-${PETSC_VERSION}.tar.gz --no-check-certificate \
		#&& tar -zxf petsc-${PETSC_VERSION}.tar.gz
		#cd $INSTALL_PATH/tmp/src/petsc-${PETSC_VERSION}
        PETSC_DIR=`pwd`

		# install petsc
		            #--with-zlib=1                   \
		            #--with-shared-libraries=1       \
		            #--with-cxx-dialect=C++11        \
		            #--download-zlib=1			    \
		            #--download-superlu=1            \
		            #--download-hypre=1              \
		            #--download-superlu_dist=1       \
		            #--download-ctetgen              \
		            #--download-superlu=1            \
		            #--download-triangle             \
		            #--useThreads=0                  \
		./configure --with-debugging=0 --prefix=$PETSC_INSTALL \
		            --COPTFLAGS="-g -O3" --CXXOPTFLAGS="-g -O3" --FOPTFLAGS="-g -O3" \
		            --with-petsc4py=1               \
		            --download-scalapack=1          \
		            --download-mumps=1              \
		            --download-metis=1              \
		            --download-parmetis=1           \
		            --download-slepc=1              \
		            --download-hdf5=1               \
		            --download-ptscotch=1           \
		            --download-bison=1              \
		            --download-mmg=1                \
		            --download-parmmg=1             \
		            --download-pragmatic=1          \
		            --download-eigen=1              \
                    --with-make-np=40               \
		            --download-cmake=1              \
                    --download-fblaslapack=1        \
		            --useThreads=0                  \
		&& make PETSC_DIR=`pwd` PETSC_ARCH=arch-linux-c-opt all \
		&& make PETSC_DIR=`pwd` PETSC_ARCH=arch-linux-c-opt install \
		&& rm -rf $INSTALL_PATH/tmp/src

		# add bin path to .zshrc file
		echo "export PYTHONPATH=\"$PETSC_INSTALL/lib:\$PYTHONPATH\"" >> ~/.bash_profile
		echo "export PETSC_DIR=$PETSC_INSTALL" >> ~/.bash_profile
		echo "export PETSC_ARCH=arch-linux-c-opt" >> ~/.bash_profile
		source ~/.bash_profile

		cd $CDIR
}

install_h5py(){
		source ${ENV_PATH}/bin/activate

        ${GIT_COMMAND_H5PY} ${INSTALL_PATH}/h5py_main
        cd ${INSTALL_PATH}/h5py_main

		CC=mpicc HDF5_MPI="ON" HDF5_DIR=$PETSC_DIR pip3 install -v .
		#CC=mpicc HDF5_MPI="ON" HDF5_DIR=$PETSC_DIR pip3 install --no-cache-dir --no-binary=h5py h5py
		pip3 install --no-cache-dir pytest
        cd $CDIR
}

install_underworld3(){
		source ${ENV_PATH}/bin/activate

		#$GIT_COMMAND ${INSTALL_PATH}/${UW3_NAME} \
		#&&
        cd ${INSTALL_PATH}/${UW3_NAME} \
		&& ./clean.sh               \
		&& python3 setup.py develop
		python3 -m pytest -v

		cd $CDIR
}

install_python_dependencies(){
		source ${ENV_PATH}/bin/activate
		#pip3 install --upgrade pip==24.3.1
	    pip3 install --no-cache-dir trame trame-vuetify trame-vtk pyvista ipywidgets nest_asyncio
	    pip3 install --no-cache-dir ipython jupyterlab jupytext
		pip3 install --upgrade --force-reinstall --no-cache-dir cython
		pip3 install --no-binary :all: --no-cache-dir numpy             # version==2.1.3
		pip3 install --no-binary :all: --no-cache-dir mpi4py            # ==4.0.0
		pip3 install --upgrade --no-cache-dir gmsh
        pip3 install --upgrade mpmath                                   #==1.3.0
        pip3 install --upgrade --force-reinstall --no-cache-dir typing-extensions
		#pip3 install --no-binary :all: --upgrade --no-cache-dir gmsh # why does this not work?!
}

check_openmpi_exists(){
        source ${ENV_PATH}/bin/activate
        return $(python${PYVER} -c "from mpi4py import MPI")
}

check_petsc_exists(){
        source ${ENV_PATH}/bin/activate
        return $(python${PYVER} -c "from petsc4py import PETSc")
}

check_underworld3_exists(){
        source ${ENV_PATH}/bin/activate
        return $(python${PYVER} -c "import underworld3")
}


install_full_stack(){

        if check_openmpi_exists; then

            install_python_dependencies

            if ! check_petsc_exists; then
              install_petsc
            fi

            install_h5py

            if ! check_underworld3_exists; then
              install_underworld3
            fi
        fi

}

if [ ! -d "$ENV_PATH" ]
then
    echo "Environment not found, creating a new one"
    mkdir -p $ENV_PATH
    python${PYVER} --version
    python${PYVER} -m venv --system-site-packages $ENV_PATH
else
    echo "Found Environment"
    source ${ENV_PATH}/bin/activate
fi
