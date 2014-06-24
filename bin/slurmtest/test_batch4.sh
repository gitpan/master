#!/bin/bash
#
#SBATCH --share
#SBATCH --get-user-env 
#SBATCH --job-name=test_4
#SBATCH --output=slurmtest/slurm_logs_2014_06_24T08_55_48cowlFpUN/test_4.log

#SBATCH --partition=hpc


#SBATCH --nodelist=hpc008

#SBATCH --cpus-per-task=4

#SBATCH --dependency=afterok:15199:15200 




perl mcerunner.pl --procs 3 --infile slurmtest/test_batch4.in --outdir slurmtest
