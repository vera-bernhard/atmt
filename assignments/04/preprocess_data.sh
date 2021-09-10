#!/bin/bash
# -*- coding: utf-8 -*-

set -e

pwd=`dirname "$(readlink -f "$0")"`
base=$pwd/../..
src=fr
tgt=en
data=$base/data/04_$tgt-$src/

# change into base directory to ensure paths are valid
cd $base

# create preprocessed directory
mkdir -p $data/preprocessed/

# normalize and tokenize raw data
cat $data/raw/train.$src | perl moses_scripts/normalize-punctuation.perl -l $src | perl moses_scripts/tokenizer.perl -l $src -a -q > $data/preprocessed/train.$src.p
cat $data/raw/train.$tgt | perl moses_scripts/normalize-punctuation.perl -l $tgt | perl moses_scripts/tokenizer.perl -l $tgt -a -q > $data/preprocessed/train.$tgt.p

# train truecase models
perl moses_scripts/train-truecaser.perl --model $data/preprocessed/tm.$src --corpus $data/preprocessed/train.$src.p
perl moses_scripts/train-truecaser.perl --model $data/preprocessed/tm.$tgt --corpus $data/preprocessed/train.$tgt.p

# apply truecase models to splits
cat $data/preprocessed/train.$src.p | perl moses_scripts/truecase.perl --model $data/preprocessed/tm.$src > $data/preprocessed/train.$src 
cat $data/preprocessed/train.$tgt.p | perl moses_scripts/truecase.perl --model $data/preprocessed/tm.$tgt > $data/preprocessed/train.$tgt

# learn joint BPE model
cat $data/preprocessed/train.$src $data/preprocessed/train.$tgt > $data/preprocessed/train.all
subword-nmt learn-bpe -s 2000 < $data/preprocessed/train.all > $data/preprocessed/bpe.codes

# apply bpe model to train splits
subword-nmt apply-bpe -c $data/preprocessed/bpe.codes < $data/preprocessed/train.$src > $data/preprocessed/train.$src.p
subword-nmt apply-bpe -c $data/preprocessed/bpe.codes < $data/preprocessed/train.$tgt > $data/preprocessed/train.$tgt.p

# remove tmp files
mv $data/preprocessed/train.$src.p $data/preprocessed/train.$src
mv $data/preprocessed/train.$tgt.p $data/preprocessed/train.$tgt

# prepare remaining splits with learned models
for split in valid test tiny_train
do
    cat $data/raw/$split.$src | perl moses_scripts/normalize-punctuation.perl -l $src | perl moses_scripts/tokenizer.perl -l $src -a -q | perl moses_scripts/truecase.perl --model $data/preprocessed/tm.$src | subword-nmt apply-bpe -c $data/preprocessed/bpe.codes > $data/preprocessed/$split.$src
    cat $data/raw/$split.$tgt | perl moses_scripts/normalize-punctuation.perl -l $tgt | perl moses_scripts/tokenizer.perl -l $tgt -a -q | perl moses_scripts/truecase.perl --model $data/preprocessed/tm.$tgt | subword-nmt apply-bpe -c $data/preprocessed/bpe.codes > $data/preprocessed/$split.$tgt
done

# preprocess all files for model training
python preprocess.py --target-lang $tgt --source-lang $src --dest-dir $data/prepared/ --train-prefix $data/preprocessed/train --valid-prefix $data/preprocessed/valid --test-prefix $data/preprocessed/test --tiny-train-prefix $data/preprocessed/tiny_train --threshold-src 1 --threshold-tgt 1 --num-words-src 4000 --num-words-tgt 4000

echo "done!"
