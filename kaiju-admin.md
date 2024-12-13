# Notes on Kaiju cluster administration and Slurm set-up 
Kaiju is a computer cluster at the ANU Research School of Earth Sciences used by Louis Moresi's computational geodynamics research group. This document provides information on how the current environment was set-up.  

## A. General Information
To get some information on the version of Operating System (OS) installed, do:
```bash
$ cat /etc/os-release 
$ grep '^VERSION' /etc/os-release
``` 
The details of the OS installed For Kaiju are:
```bash
NAME="Rocky Linux"
VERSION="8.10 (Green Obsidian)"
ID="rocky"
ID_LIKE="rhel centos fedora"
VERSION_ID="8.10"
PLATFORM_ID="platform:el8"
PRETTY_NAME="Rocky Linux 8.10 (Green Obsidian)"
ANSI_COLOR="0;32"
LOGO="fedora-logo-icon"
CPE_NAME="cpe:/o:rocky:rocky:8:GA"
HOME_URL="https://rockylinux.org/"
BUG_REPORT_URL="https://bugs.rockylinux.org/"
SUPPORT_END="2029-05-31"
ROCKY_SUPPORT_PRODUCT="Rocky-Linux-8"
ROCKY_SUPPORT_PRODUCT_VERSION="8.10"
REDHAT_SUPPORT_PRODUCT="Rocky Linux"
REDHAT_SUPPORT_PRODUCT_VERSION="8.10"
```

Rocky Linux is a Linux distribution mean to replace CentOS, a production-ready downstream version of RHEL. This means that Rocky Linux can run the same software as CentOS and be used for the same purposes.

To determine the Linux kernel version:
```bash
$ uname -r
```

To determine the architecture: 
```bash
$ arch
```


## B. Kaiju environment set-up

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

Kaiju was set-up such that everything in ```/opt/cluster``` are available to all nodes via NFS. Thus, any software that is needed by all nodes should be installed in this directory. To install a \<package\>, IF YOU REALLY NEED TO, do the following steps:

```bash
$ dnf repoquery --whatprovides <package> #  display all available packages providing "package"
$ sudo pdsh -f 10 -w n[0-4] dnf -y install <some-package>|sort -st: -nk1.2 # install "some-package" in nodes 0 to 4
```
The ```-f``` flag sets the maximum number of simultaneous remote commands, while ```-w``` sets the target of the commands. The ```sudo``` command above indicates that you are running the command as a super user. As much as possible, it is recommended that only the administrator of should install the packages, but let's worry about this later (i.e. "let's cross the bridge when we get there"). 

By default, users log-in into the head node. One may log-in into a compute node, say n1, with ```ssh n1```.


## C. Spack installation and set-up
We have decided to use Spack as a package manager. It is quite easy to use and seems good at separating packages handling dependencies. Note that the installation instructions are for the information of future system administrators and regular users need not worry about this. More detailed installation instructions can be found [here](https://spack.readthedocs.io/en/latest/getting_started.html#system-prerequisitesrpm). To install spack in the entire cluster as a superuser:

1. Make sure that the system prerequisites given in the link above are installed in _all_ nodes.

2. Inside ```/opt/cluster```, run:

```bash
$ git clone -c feature.manyFiles=true --depth=2 https://github.com/spack/spack.git
```

This will create a directory ```spack```. 

3. To make ```spack``` accessible to all users, createa or append to file ```/etc/profile.d/spack.sh``` and put the following inside it:

```bash
. /opt/cluster/spack/share/spack/setup-env.sh
```

4. It may be necessary to install mesa-libGLU to resolve some issues: 

```bash
$ pdsh -f 10 -w n[0-8] dnf -y install mesa-libGLU|sort -st: -nk1.2
```

## D. Munge installation and set-up
Before we can install Slurm, it is necessary to install and set-up Munge first. Munge is an authentication service to create and validate credentials. This enables Slurm to authenticate the UID and GID of a request from other hosts with matching users and groups. Helpful online references for setting-up Munge can be found [here](https://github.com/SergioMEV/slurm-for-dummies?tab=readme-ov-file#setup-munge) and [here](https://affan.info/hpc/#step-6-configure-slurm-workload-manager).

1. Update all node systems: 
```bash 
$ sudo dnf update -y
```

2. Install munge on the _head_ node:
```bash
$ dnf install munge munge-libs munge-devel -y
```

3. Configure the Munge key. Munge requires a secret shared across all nodes in the cluster to authenticate the messages between them. We need to create a key on the first node and distribute it to other nodes. To create a key:

```bash
$ sudo create-munge-key
```

The created key is found in ```/etc/munge/```. Later, we will need to copy it into the compute nodes, so it's a good idea to save it somewhere easily accessible.

4. Set-up the correct permissions for the munge user:

```bash
$ sudo chown -R munge: /etc/munge/ /var/log/munge/ /var/lib/munge/ /run/munge/
$ sudo chmod 0700 /etc/munge/ /var/log/munge/ /var/lib/munge/
$ sudo chmod 0755 /run/munge/
$ sudo chmod 0700 /etc/munge/munge.key
$ sudo chown -R munge: /etc/munge/munge.key
```

5. Start the munge "controller" daemon and set it to run at start-up. This is done by:
```bash
$ systemctl enable munge
$ systemctl start munge
```

6. To monitor the status of the munge daemon (i.e. is it running or not):
```bash
$ systemctl status munge
```
or read the contents of the log file in ```/var/log/munge/munged.log```

7. Install munge in the compute nodes. It may be necessary to install munge-devel using a different way:
```bash
$ dnf --enablerepo=devel install munge-devel
```

8. The munge key should be consistent throughout all nodes. Replace the compute nodes' ```munge.key``` in ```/etc/munge``` with the controller node's ```munge.key``` file (see end of step 3).

9. Properly set-up munge's permissions in the compute nodes:
```bash
$ sudo chown -R munge: /etc/munge/ /var/log/munge/ /var/lib/munge/ /run/munge/
$ sudo chmod 0700 /etc/munge/ /var/log/munge/ /var/lib/munge/
$ sudo chmod 0755 /run/munge/
$ sudo chmod 0700 /etc/munge/munge.key
$ sudo chown -R munge: /etc/munge/munge.key
```

10. Start the munge "worker" daemon in each compute node:
```bash
$ systemctl enable munge
$ systemctl start munge
```

11. Test munge's connection to the controller node by:
```bash
$ munge -n | ssh n0 unmunge | grep STATUS
```
If connection exists, the output should be:
```bash
STATUS:           Success (0)
```

## E. Slurm installation and set-up
Slurm is an open source cluster management and job scheduling system for Linux clusters. Honestly, this is a bit tricky to set-up and it took a while for it to be successfully installed. Some helpful references include: [here](https://slurm.schedmd.com/quickstart_admin.html#prereqs), [here](https://github.com/SergioMEV/slurm-for-dummies?tab=readme-ov-file#setup-munge), and [here](https://affan.info/hpc/#step-6-configure-slurm-workload-manager). While the installation instructions work, they may not be the most efficient:

1. Make sure that the clocks across all nodes are synchronized by checking them:
```bash
$ pdsh -f 10 -w n[0-4] date -Ins|sort -st: -nk1.2
```
If they are not, then sync-ing packages need to be installed like ```chrony``` in ALL nodes.

2. Install extra packages for Linux in ALL nodes:
```bash
$ sudo dnf install -y epel-release
```

3. Install slurm and its dependencies on the HEAD node:
```bash
$ sudo dnf install slurm slurm-slurmctld -y
```
The "ctld" indicates that this will be the controller daemon.

4. Install slurm and its dependencies on the COMPUTE nodes:
```bash
$ sudo dnf install slurm slurm-slurmd -y
```
The "d" indicates that this is NOT the controller daemon.

5. For security reasons, it is recommended to create a special user (e.g. named ```slurm```) for running/controlling slurm (TODO: improve reasoning) which has no elevated privileges. The UIDs and GIDs of all cluster users are made consistent throughout the cluster with NIS. However, I don't know yet how to automatically sync this so I've manually created the ```slurm``` users in all nodes and set them to have consistent UIDs and GIDs. For example, we want to create a user named ```slurm``` with the following UID, GID, and group:
```bash
$ uid=961(slurm) gid=961(slurm) groups=961(slum)
``` 
We can do this by running on each node:
```bash
$ groupadd -g 961 slurm
$ useradd -u 961 -g 961 slurm
```
Note that jobs will not run correctly if the UID and GID of the ```slurm``` user in a COMPUTE node differs from the HEAD node.   

6. After this, we create directories for the Slurm controller daemon and set the appropriate file permissions. On the HEAD node:

```bash
$ sudo mkdir -p /var/spool/slurmctld
$ sudo chown slurm: /var/spool/slurmctld
$ sudo touch /var/log/slurmctld.log
$ sudo chown slurm: /var/log/slurmctld.log
```

7. We edit the HEAD node's Slurm configuration file as needed. This file is in ```/etc/slurm/slurm.conf```. The configurations we are currently using are as follows:

```bash
 SlurmctldHost=kaiju.anu.edu.au
 #MailProg=/bin/mail
 MpiDefault=none
 #MpiParams=ports=#-#
 ProctrackType=proctrack/pgid
 ReturnToService=1
 SlurmctldPidFile=/var/run/slurmctld.pid
 #SlurmctldPort=6817
 SlurmdPidFile=/var/run/slurmd.pid
 #SlurmdPort=6818
 SlurmdSpoolDir=/var/spool/slurmd
 SlurmUser=slurm
 #SlurmdUser=root # not recommended to be root
 StateSaveLocation=/var/spool/slurmctld
 SwitchType=switch/none
 TaskPlugin=task/none
 #
 #
 # TIMERS
 #KillWait=30
 #MinJobAge=300
 #SlurmctldTimeout=120
 #SlurmdTimeout=300
 #
 #
 # SCHEDULING
 SchedulerType=sched/backfill
 SelectType=select/cons_tres
 SelectTypeParameters=CR_Core
 #
 #
 # LOGGING AND ACCOUNTING
 AccountingStorageType=accounting_storage/none
 ClusterName=kaiju
 #JobAcctGatherFrequency=30
 JobAcctGatherType=jobacct_gather/none
 SlurmctldDebug=info
 SlurmctldLogFile=/var/log/slurmctld.log
 SlurmdDebug=info
 SlurmdLogFile=/var/log/slurmd.log
 #
 #
 # COMPUTE NODES
 NodeName=n[1-4] CPUs=104 Sockets=2 CoresPerSocket=26 ThreadsPerCore=2 State=UNKNOWN
 PartitionName=debug Nodes=n[1-4] Default=YES MaxTime=INFINITE State=UP
```
The important settings are the following: ```SlurmctldHost, SlurmUser, SlurmctldLogFile, SlurmdLogFile```, and those related to the COMPUTE nodes. When making a lot of changes, one can use the configuration file generator for Slurm Version 20.11 [here](https://haddock.marseille.inserm.fr/slurm/configurator.easy.html). Do note that different slurm versions may have different configuration keys which should be considered. We will need to copy this file into the COMPUTE nodes, so saving this somewhere easily accessible is recommended. 

8. Since we've already created the ```slurm``` user in all the COMPUTE nodes, we create directories for the Slurm daemon and set the needed file permissions. On the COMPUTE nodes:

```bash
sudo mkdir -p /var/spool/slurmd
sudo chown slurm: /var/spool/slurmd
sudo touch /var/log/slurmd.log
sudo chown slurm: /var/log/slurmd.log
```

Note that these refer to ```slurmd``` and not ```slurmctld```.

9. Copy the ```slurm.conf``` file from the HEAD node into ```/etc/slurm/``` of the COMPUTE nodes. Slurm will not run if the ```slurm.conf``` files are inconsistent throughout the cluster.

10. Start the slurm controller daemon, ```slurmctld```, and check it's status on the HEAD node by:

```bash
$ sudo systemctl start slurmctld
$ sudo systemctl status slurmctld
```

11. Start the slurm daemon, ```slurmd```, and check it's status on the COMPUTE nodes by:

```bash
$ sudo systemctl start slurmd
$ sudo systemctl status slurmd
```

These commands can be used to control the slurmd or slurmctld daemons:
```bash
$ sudo systemctl stop slurmd        # or slurmctld
$ sudo systemctl disable slurmd
$ sudo systemctl enable slurmd 
$ sudo systemctl restart slurmd 
```

12. After turning ```slurmctld``` and all the ```slurmd```, we can check the status of all the nodes (e.g. IDLE, UNK, etc.) with:

```bash
$ sinfo
```

## F. Modular installation of packages with Spack
As mentioned in Section C, Spack is a package manager that allows for modular installation of different packages. That is, a user can load/unload the different packages (along w/ versions) needed. Some basic Spack commands are as follows:

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

It is worth noting that when Spack is used with Slurm, we need to let Spack know the location of Slurm in th system. To automatically do this:

```bash
$ sudo spack external find slurm
```

This will add Slurm to /root/.spack/packages.yaml. 

When installing openmpi with Spack, we must also specify that we are using this with Slurm. This is done by:

```bash
spack install openmpi@4.1.6 schedulers=slurm
```

Do note that when this is done, we cannot use mpirun or mpiexec as discussed [here]().










