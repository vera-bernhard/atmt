#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# Example call:
#   bash scripts/run_preprocessing.sh

set -e

raw_data=$1

# set languages
src_lang=en
tgt_lang=sv

# set paths
scripts=`dirname "$(readlink -f "$0")"`
base=$scripts/..
moses_scripts=$base/moses_scripts
preprocessed=$raw_data/../preprocessed
prepared=$raw_data/../prepared

mkdir -p $preprocessed
mkdir -p $prepared

for lang in $src_lang $tgt_lang
    do
        echo "training truecase model for $lang"

        # normalise and tokenize punctuation in training
        # split for truecase model training
        cat $raw_data/train.$lang | perl $moses_scripts/normalize-punctuation.perl -l $lang | perl $moses_scripts/tokenizer.perl -l $lang -a -q > $preprocessed/train.$lang
        
        # train truecase model for language
        perl $moses_scripts/train-truecaser.perl --model $preprocessed/tm.$lang --corpus $preprocessed/train.$lang
        
        # normalise, tokenise and apply truecase model to each data split
        for split in train tiny_train test valid
            do
                echo "preprocessing $split split for language $lang..."            
                cat $raw_data/$split.$lang | perl $moses_scripts/normalize-punctuation.perl -l $lang | perl $moses_scripts/tokenizer.perl -l $lang -a -q | perl $moses_scripts/truecase.perl --model $preprocessed/tm.$lang >| $preprocessed/$split.$lang
                
            done
    done

echo "preparing data for model training..."

python $base/preprocess.py \
    --source-lang $src_lang \
    --target-lang $tgt_lang \
    --dest-dir $prepared \
    --train-prefix $preprocessed/train \
    --valid-prefix $preprocessed/valid \
    --test-prefix $preprocessed/test \
    --tiny-train-prefix $preprocessed/tiny_train \
    --threshold-src 1 \
    --threshold-tgt 1 \
    --num-words-src 4000 \
    --num-words-tgt 4000

echo "done."




# cat $raw_data/train.$tgt_lang | perl $moses_scripts/normalize-punctuation.perl -l $tgt_lang | perl $moses_scripts/tokenizer.perl -l $tgt_lang -a -q > $preprocessed/train.$tgt_lang.p

# perl $moses_scripts/train-truecaser.perl --model $preprocessed/tm.$tgt_lang --corpus $preprocessed/train.$tgt_lang.p

# apply truecase model to train



# cat $preprocessed/train.$tgt_lang.p | perl $moses_scripts/truecase.perl --model $preprocessed/tm.$tgt_lang > $preprocessed/train.$tgt_lang 

# apply truecase model to valid
# cat baseline/raw_data/valid.de | perl $moses_scripts/normalize-punctuation.perl -l de | perl $moses_scripts/tokenizer.perl -l de -a -q | perl $moses_scripts/truecase.perl --model baseline/preprocessed_data/tm.de > baseline/preprocessed_data/valid.de

# cat baseline/raw_data/valid.en | perl $moses_scripts/normalize-punctuation.perl -l en | perl $moses_scripts/tokenizer.perl -l en -a -q | perl $moses_scripts/truecase.perl --model baseline/preprocessed_data/tm.en > baseline/preprocessed_data/valid.en

# # apply truecase model to test
# cat baseline/raw_data/test.de | perl $moses_scripts/normalize-punctuation.perl -l de | perl $moses_scripts/tokenizer.perl -l de -a -q | perl $moses_scripts/truecase.perl --model baseline/preprocessed_data/tm.de > baseline/preprocessed_data/test.de

# cat baseline/raw_data/test.en | perl $moses_scripts/normalize-punctuation.perl -l en | perl $moses_scripts/tokenizer.perl -l en -a -q | perl $moses_scripts/truecase.perl --model baseline/preprocessed_data/tm.en > baseline/preprocessed_data/test.en

# cat baseline/raw_data/tiny_train.de | perl $moses_scripts/normalize-punctuation.perl -l de | perl $moses_scripts/tokenizer.perl -l de -a -q | perl $moses_scripts/truecase.perl --model baseline/preprocessed_data/tm.de > baseline/preprocessed_data/tiny_train.de

# cat baseline/raw_data/tiny_train.en | perl $moses_scripts/normalize-punctuation.perl -l en | perl $moses_scripts/tokenizer.perl -l en -a -q | perl $moses_scripts/truecase.perl --model baseline/preprocessed_data/tm.en > baseline/preprocessed_data/tiny_train.en


# rm baseline/preprocessed_data/train.de.p
# rm baseline/preprocessed_data/train.en.p

# python preprocess.py --target-lang en --source-lang de --dest-dir baseline/prepared_data/ --train-prefix baseline/preprocessed_data/train --valid-prefix baseline/preprocessed_data/valid --test-prefix baseline/preprocessed_data/test --tiny-train-prefix baseline/preprocessed_data/tiny_train --threshold-src 1 --threshold-tgt 1 --num-words-src 4000 --num-words-tgt 4000
