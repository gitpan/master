#!/bin/bash
#
#SBATCH --share
#SBATCH --get-user-env 
#SBATCH --job-name=test_3
#SBATCH --output=slurmtest/slurm_logs_2014_06_24T08_55_48cowlFpUN/test_3.log

#SBATCH --partition=hpc


#SBATCH --nodelist=hpc007

#SBATCH --cpus-per-task=4

#SBATCH --dependency=afterok:15198 




perl mcerunner.pl --procs 3 --infile slurmtest/test_batch3.in --outdir slurmtest
