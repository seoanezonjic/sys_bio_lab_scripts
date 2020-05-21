# /usr/bin/env bash
#module load sra_toolkit
. ~soft_bio_267/initializes/init_sratoolkit
#$1 : File with SRA identifiers (one per line) to download

# CONFIG:::
mkdir -p $SCRATCH'/sra_download'
mkdir -p  ~/.ncbi
echo -e '/LIBS/GUID = "180ce9b5-d384-4446-b76f-3a94a9618a7e"
/config/default = "false"
/gcp/credential_file = "/mnt/home/soft/soft_bio_267/programs/x86_64/sratoolkit/cool-reach-275610-bdbda0940c14.json"
/libs/cloud/report_instance_identity = "true"
/repository/user/ad/public/apps/file/volumes/flatAd = "."
/repository/user/ad/public/apps/refseq/volumes/refseqAd = "."
/repository/user/ad/public/apps/sra/volumes/sraAd = "."
/repository/user/ad/public/apps/sraPileup/volumes/ad = "."
/repository/user/ad/public/apps/sraRealign/volumes/ad = "."
/repository/user/ad/public/root = "."
/repository/user/default-path = "'$HOME'/ncbi"
/repository/user/main/public/root = "'$SCRATCH'/sra_download"' > ~/.ncbi/user-settings.mkfg
#aspera_folder="~soft_bio_267/programs/x86_64/aspera/connect"
for i in `cat $1`
do
    #prefetch --ascp-path "$aspera_folder/bin/ascp|$aspera_folder/etc/asperaweb_id_dsa.openssh" --max-size 200000000 $2 "${i}"
    srapath "${i}"
    prefetch -X 200000000 $2 "${i}"
    #prefetch -X 200000000 $2 "${i}"
    sleep 10
done

