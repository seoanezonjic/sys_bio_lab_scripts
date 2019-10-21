# /usr/bin/env bash
module load sra_toolkit
#$1 : File with SRA identifiers (one per line) to download

# CONFIG:::
mkdir -p $SCRATCH'/sra_download'
mkdir -p  ~/.ncbi
echo '/repository/user/main/public/root = "'$SCRATCH'/sra_download"' > ~/.ncbi/user-settings.mkfg
aspera_folder="~soft_bio_267/programs/x86_64/aspera/connect"
for i in `cat $1`
do
    prefetch --ascp-path "$aspera_folder/bin/ascp|$aspera_folder/etc/asperaweb_id_dsa.openssh" --max-size 200000000 $2 "${i}"
    sleep 10
done

