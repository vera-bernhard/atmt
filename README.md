# atmt code base
Materials for the first assignment of "Advanced Techniques of Machine Translation".
Please refer to the assignment sheet for instructions on how to use the toolkit.

The toolkit is based on [this implementation](https://github.com/demelin/nmt_toolkit).


# Environment Setup

### conda

```
# ensure that you have conda (or miniconda) installed (https://conda.io/projects/conda/en/latest/user-guide/install/index.html) and that it is activated

# create clean environment
conda create --name atmt36 python=3.6

# activate the environment
conda activate atmt36

# intall required packages
pip install torch==1.6.0 numpy tqdm sacrebleu
```

### virtualenv

```
# ensure that you have python 3.6 downloaded and installed (https://www.python.org/downloads/)

# install virtualenv
pip install virtualenv

# create a virtual environment named "atmt36"
virtualenv --python=python3 atmt36

# launch the newly created environment
atmt36/bin/activate

# intall required packages
pip install torch==1.6.0 numpy tqdm sacrebleu
```

<!-- # Data Preprocessing

```
# normalise, tokenize and truecase data
bash scripts/extract_splits.sh ../infopankki_raw data/en-sv/infopankki/raw

# binarize data for model training
bash scripts/run_preprocessing.sh data/en-sv/infopankki/raw/
``` -->

# Training a model

```
python train.py \
    --data data/en-sv/infopankki/prepared/ \
    --source-lang en \
    --target-lang sv \
    --save-dir assignments/01/checkpoints \
    --train-on-tiny # for testing purposes only
```

Note, only use `--train-on-tiny` for testing. This will train a
dummy model on the `tiny_train` split.

# Evaluating a trained model

Run inference on test set
```
python translate.py \
    --data data/en-sv/infopankki/prepared/ \
    --dicts data/en-sv/infopankki/prepared/ \
    --checkpoint-path assignments/01/checkpoints/checkpoint_last.pt \
    --output assignments/01/model_translations.txt
```

Postprocess model translations
```
bash scripts/postprocess.sh assignments/01/model_translations.txt assignments/01/model_translations.post.txt sv
```

Score with SacreBLEU
```
cat assignments/01/model_translations.post.txt | sacrebleu data/en-sv/infopankki/raw/test.sv
```

# Assignments

- [ ] Assignment 1: Training and evaluating an NMT model
  with in-domain and out-of-domain data
- [ ] Assignment 2: ??
- [ ] Assignment 3: ??
- [ ] Assignment 4: ??
- [ ] Assignment 5: ??


