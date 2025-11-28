# /usr/bin/env bash
#module load sra_toolkit
#module load ncbi_cpp_toolkit/12.0.0
#. ~soft_cvi_114/initializes/init_sratoolkit
#. ~soft_bio_267/initializes/init_sratoolkit
. ~soft_bio_267/initializes/init_parallel_fastqdump

# CONFIG:::
# echo '/repository/user/main/public/root = "/mnt/scratch/users/pab_001_uma/pedro/sra_download"' > ~/.ncbi/user-settings.mkfg
# $1 list file with sra ids
# $2 path to folder with sra files
# $3 output folder
# $4 aditional options for fastq-dump
for i in `cat $1`
do
    parallel-fastq-dump --sra-id $2"/"${i}".sra" --outdir $3 --split-files --gzip --origfmt $4
    #fastq-dump --split-files --gzip --origfmt $4 --outdir $3 $2"/"${i}".sra"
done

