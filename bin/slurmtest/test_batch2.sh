#!/bin/bash
#
#SBATCH --share
#SBATCH --get-user-env 
#SBATCH --job-name=test_2
#SBATCH --output=slurmtest/slurm_logs_2014_06_24T08_55_48cowlFpUN/test_2.log

#SBATCH --partition=hpc


#SBATCH --nodelist=hpc006

#SBATCH --cpus-per-task=4

#SBATCH --dependency=afterok:15198 




perl mcerunner.pl --procs 3 --infile slurmtest/test_batch2.in --outdir slurmtest
