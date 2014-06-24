#!/bin/bash
#
#SBATCH --share
#SBATCH --get-user-env 
#SBATCH --job-name=test_1
#SBATCH --output=slurmtest/slurm_logs_2014_06_24T08_55_48cowlFpUN/test_1.log

#SBATCH --partition=hpc


#SBATCH --nodelist=hpc005

#SBATCH --cpus-per-task=4




perl mcerunner.pl --procs 3 --infile slurmtest/test_batch1.in --outdir slurmtest
