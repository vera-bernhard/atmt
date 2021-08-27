#!/bin/bash
# -*- coding: utf-8 -*-

set -e

pwd=`dirname "$(readlink -f "$0")"`
base=$pwd/../..
data=$base/data/en-fr/

# change into base directory to ensure paths are valid
cd $base

# create preprocessed directory
mkdir -p $data/preprocessed/

# normalize and tokenize raw data
cat $data/raw/train.fr | perl moses_scripts/normalize-punctuation.perl -l fr | perl moses_scripts/tokenizer.perl -l fr -a -q > $data/preprocessed/train.fr.p
cat $data/raw/train.en | perl moses_scripts/normalize-punctuation.perl -l en | perl moses_scripts/tokenizer.perl -l en -a -q > $data/preprocessed/train.en.p

# train truecase models
perl moses_scripts/train-truecaser.perl --model $data/preprocessed/tm.fr --corpus $data/preprocessed/train.fr.p
perl moses_scripts/train-truecaser.perl --model $data/preprocessed/tm.en --corpus $data/preprocessed/train.en.p

# apply truecase models to splits
cat $data/preprocessed/train.fr.p | perl moses_scripts/truecase.perl --model $data/preprocessed/tm.fr > $data/preprocessed/train.fr 
cat $data/preprocessed/train.en.p | perl moses_scripts/truecase.perl --model $data/preprocessed/tm.en > $data/preprocessed/train.en

# prepare remaining splits with learned models
for split in valid test tiny_train
do
    cat $data/raw/$split.fr | perl moses_scripts/normalize-punctuation.perl -l fr | perl moses_scripts/tokenizer.perl -l fr -a -q | perl moses_scripts/truecase.perl --model $data/preprocessed/tm.fr > $data/preprocessed/$split.fr
    cat $data/raw/$split.en | perl moses_scripts/normalize-punctuation.perl -l en | perl moses_scripts/tokenizer.perl -l en -a -q | perl moses_scripts/truecase.perl --model $data/preprocessed/tm.en > $data/preprocessed/$split.en
done

# remove tmp files
rm $data/preprocessed/train.fr.p
rm $data/preprocessed/train.en.p

# preprocess all files for model training
python preprocess.py --target-lang en --source-lang fr --dest-dir $data/prepared/ --train-prefix $data/preprocessed/train --valid-prefix $data/preprocessed/valid --test-prefix $data/preprocessed/test --tiny-train-prefix $data/preprocessed/tiny_train --threshold-src 1 --threshold-tgt 1 --num-words-src 4000 --num-words-tgt 4000

echo "done!"