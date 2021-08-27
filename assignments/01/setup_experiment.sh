#!/bin/bash
# -*- coding: utf-8 -*-

set -e

pwd=`dirname "$(readlink -f "$0")"`
base=$pwd/../..

cd $base
echo "changed dir into $base"

echo ""
echo "preparing data..."
echo ""

python scripts/extract_splits.py \
    --src /mnt/storage/clwork/users/kew/HS2021/infopankki_raw/infopankki.en-sv.sv \
    --tgt /mnt/storage/clwork/users/kew/HS2021/infopankki_raw/infopankki.en-sv.en \
    --outdir data/en-sv/infopankki/raw

bash scripts/preprocess_data.sh data/en-sv/infopankki/raw/ sv en

echo ""
echo "preparing OOD data..."
echo ""

for domain in bible_uedin TED2020
do
    python scripts/extract_splits.py \
        --src /mnt/storage/clwork/users/kew/HS2021/${domain}_raw/*.en-sv.sv \
        --tgt /mnt/storage/clwork/users/kew/HS2021/${domain}_raw/*.en-sv.en \
        --outdir data/en-sv/$domain/raw

    bash scripts/preprocess_data.sh data/en-sv/$domain/raw sv en

    echo ""
    echo "cleaning unwanted files..."
    echo ""
    for data_type in raw preprocessed prepared
    do
        rm -rf data/en-sv/$domain/$data_type/train*
        rm -rf data/en-sv/$domain/$data_type/tiny_train*
        rm -rf data/en-sv/$domain/$data_type/valid*
        rm -rf data/en-sv/$domain/$data_type/tm*
        rm -rf data/en-sv/$domain/$data_type/dict*
    done
done
