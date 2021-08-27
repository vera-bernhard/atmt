#!/bin/bash
# -*- coding: utf-8 -*-

set -e

pwd=`dirname "$(readlink -f "$0")"`
base=$pwd/../..
data=$base/data/en-de/

# change into base directory to ensure paths are valid
cd $base

# create preprocessed directory
mkdir -p $data/preprocessed/

# normalize and tokenize raw data
cat $data/raw/train.de | perl moses_scripts/normalize-punctuation.perl -l de | perl moses_scripts/tokenizer.perl -l de -a -q > $data/preprocessed/train.de.p
cat $data/raw/train.en | perl moses_scripts/normalize-punctuation.perl -l en | perl moses_scripts/tokenizer.perl -l en -a -q > $data/preprocessed/train.en.p

# train truecase models
perl moses_scripts/train-truecaser.perl --model $data/preprocessed/tm.de --corpus $data/preprocessed/train.de.p
perl moses_scripts/train-truecaser.perl --model $data/preprocessed/tm.en --corpus $data/preprocessed/train.en.p

# apply truecase models to train splits
cat $data/preprocessed/train.de.p | perl moses_scripts/truecase.perl --model $data/preprocessed/tm.de > $data/preprocessed/train.de
cat $data/preprocessed/train.en.p | perl moses_scripts/truecase.perl --model $data/preprocessed/tm.en > $data/preprocessed/train.en

# learn joint BPE model
cat $data/preprocessed/train.de  $data/preprocessed/train.en >  $data/preprocessed/train.all
subword-nmt learn-bpe -s 2000 <  $data/preprocessed/train.all >  $data/preprocessed/bpe.codes

# apply bpe model to train splits
subword-nmt apply-bpe -c  $data/preprocessed/bpe.codes <  $data/preprocessed/train.de >  $data/preprocessed/train.de.p
subword-nmt apply-bpe -c  $data/preprocessed/bpe.codes <  $data/preprocessed/train.en >  $data/preprocessed/train.en.p

# replace original file with preprocessed files
mv $data/preprocessed/train.de.p  $data/preprocessed/train.de
mv $data/preprocessed/train.en.p  $data/preprocessed/train.en

# prepare remaining splits with learned models
for split in valid test tiny_train
do
    cat $data/raw/$split.de | perl moses_scripts/normalize-punctuation.perl -l de | perl moses_scripts/tokenizer.perl -l de -a -q | perl moses_scripts/truecase.perl --model $data/preprocessed/tm.de | subword-nmt apply-bpe -c  $data/preprocessed/bpe.codes > $data/preprocessed/$split.de
    cat $data/raw/$split.en | perl moses_scripts/normalize-punctuation.perl -l en | perl moses_scripts/tokenizer.perl -l en -a -q | perl moses_scripts/truecase.perl --model $data/preprocessed/tm.en | subword-nmt apply-bpe -c  $data/preprocessed/bpe.codes > $data/preprocessed/$split.en
done

# preprocess all files for model training
python preprocess.py --target-lang en --source-lang de --dest-dir $data/prepared/ --train-prefix $data/preprocessed/train --valid-prefix $data/preprocessed/valid --test-prefix $data/preprocessed/test --tiny-train-prefix $data/preprocessed/tiny_train --threshold-src 1 --threshold-tgt 1 --num-words-src 4000 --num-words-tgt 4000

echo "done!"