# Kaiju quick user guide
Kaiju is a computer cluster at the ANU Research School of Earth Sciences used by Louis Moresi's computational geodynamics research group. This document is a quick guide for users.

## A. Important general information 
Kaiju is composed of a head node and 8 compute nodes. Information on the IP hostnames, addresses, and aliases of the nodes are found in ```/etc/hosts```. Opening it, we see:

```bash
150.203.8.145   kaiju.anu.edu.au kaiju
192.168.32.2    switch.cluster switch

192.168.32.1    node00.cluster node00 n0 kaiju.cluster head
192.168.32.11   node01.cluster node01 n1
192.168.32.12   node02.cluster node02 n2
192.168.32.13   node03.cluster node03 n3
192.168.32.14   node04.cluster node04 n4
192.168.32.15   node05.cluster node05 n5
192.168.32.16   node06.cluster node06 n6
192.168.32.17   node07.cluster node07 n7
192.168.32.18   node08.cluster node08 n8
```

As of December 11, 2024, compute nodes n5 to n8 are down so we can only use nodes n1 to n4. To determine the total number of CPUs in each node, run ```nproc```. To determine the number and detailed hardware specifications of each node, one can run ```lscpu```. Running ```lscpu``` for the head node:

```bash
Architecture:        x86_64
CPU op-mode(s):      32-bit, 64-bit
Byte Order:          Little Endian
CPU(s):              40
On-line CPU(s) list: 0-39
Thread(s) per core:  2
Core(s) per socket:  10
Socket(s):           2
NUMA node(s):        2
Vendor ID:           GenuineIntel
CPU family:          6
Model:               85
Model name:          Intel(R) Xeon(R) Silver 4210R CPU @ 2.40GHz
Stepping:            7
CPU MHz:             2400.000
CPU max MHz:         3200.0000
CPU min MHz:         1000.0000
BogoMIPS:            4800.00
L1d cache:           32K
L1i cache:           32K
L2 cache:            1024K
L3 cache:            14080K
NUMA node0 CPU(s):   0-9,20-29
NUMA node1 CPU(s):   10-19,30-39
```

For the compute nodes: 

```bash
Architecture:        x86_64
CPU op-mode(s):      32-bit, 64-bit
Byte Order:          Little Endian
CPU(s):              104
On-line CPU(s) list: 0-103
Thread(s) per core:  2
Core(s) per socket:  26
Socket(s):           2
NUMA node(s):        2
Vendor ID:           GenuineIntel
CPU family:          6
Model:               85
Model name:          Intel(R) Xeon(R) Gold 6230R CPU @ 2.10GHz
Stepping:            7
CPU MHz:             2100.000
CPU max MHz:         4000.0000
CPU min MHz:         1000.0000
BogoMIPS:            4200.00
L1d cache:           32K
L1i cache:           32K
L2 cache:            1024K
L3 cache:            36608K
NUMA node0 CPU(s):   0-25,52-77
NUMA node1 CPU(s):   26-51,78-103
```
Thus, the head node has a total of 40 CPUs, while _each_ compute node has 104 CPUs.

## B. Spack as a package manager

Spack is used as a package manager. It is quite easy to use and seems good at separating packages handling dependencies. Having said that, users generally only have to load the package that they need. System-wide installations are usually left to the system administrators (to confirm). Some basic commands are as follows: 

```bash
$ spack find                        # lists all the packages installed in cluster
$ spack list                        # lists available packages that can be installed 
$ sudo spack install <package>      # install package 
$ sudo spack uninstall <package>    # uninstall package 
$ spack load <package>              # loads the package
$ spack unload <package>            # unloads a package
$ spack find --loaded               # lists the loaded package
$ spack info --all <package>        # get info including available versions of a package
```

Good documentation regarding its basic usage can be found [here](https://spack.readthedocs.io/en/latest/basic_usage.html)

Also note that we can specify the package version using the @. For example, ```python@3.12.5```.

## C. Slurm as job scheduler 
Slurm is an open source cluster management and job scheduling system for Linux clusters. Users need to submit jobs to Slurm and it will schedule the execution of those jobs according to the load in the cluster. Some basic commands are: 

```bash
$ sbatch <job script>           # submit job described in job script
$ squeue                        # lists the jobs in queue in the cluster
$ scontrol show nodes           # shows information on each node (e.g. load, status)
```

## D. Installation and running Underworld 3
1. At present, only a bare-metal installation of underworld3 is available (Docker soon). To do so, just follow the instructions inside uw3_install_kaiju_run.sh. Note that for Kaiju, Python and Open MPI are already installed and users just need to load them using Spack. This loading is already done inside uw3_install_kaiju_run.sh.  

2. To test your installation, copy ```mpi_job.sh``` and ```poisson_uw3.py``` into a directory of your choice. Afterwards, change the permissions for this directory with ```chmod 707 <directory name>```. This is necessary for the Slurm daemon to write any outputs into this directory (FIXME: change such that chmod is not needed). Edit ```mpi_job.sh``` as necessary and submit job with ```sbatch mpi_job.sh```. Check the outputs to see if the job ran successfully.

3. To run your own model, just create a copy of ```mpi_job.sh``` and change the file name that's run inside. Also, don't forget to change the permissions of the directory containing the model script as stated in the previous ste. Inside the job script file (e.g. mpi_job.sh), you can change the following options: 

```bash
--job-name=<job name that you want>
--output=<name of the output log file>
--ntasks=<number of tasks>
--cpus-per-task=<number of cpus per task; total number of cpus used is ntasks * cpus-per-task>
--time=<maximum amount of time that your job will run in HH:MM:SS>
--nodes=<number of nodes you wish to use; optional setting>
--ntasks-per-node=<number of tasks per node; optional setting>
```

Please make sure that the following commands are inside the job script (FIXME: list reasons):

```bash
export PMIX_MCA_psec=native
export OMPI_MCA_btl_tcp_if_include=eno1
srun --mpi=pmix
```
