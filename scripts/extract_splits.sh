#!/usr/bin/env bash
# -*- coding: utf-8 -*-

#########
# Example call:
# bash scripts/extract_splits.sh data/en-sv/infopankki_raw data/en-sv/splits_raw/
#########

indir=$1
outdir=$2

mkdir -p $outdir

head -n 10000 $indir/infopankki.en-sv.sv >| $outdir/train.sv
head -n 10000 $indir/infopankki.en-sv.en >| $outdir/train.en

head -n 10500 $indir/infopankki.en-sv.sv | tail -n 500 >| $outdir/dev.sv
head -n 10500 $indir/infopankki.en-sv.en | tail -n 500 >| $outdir/dev.en

head -n 11000 $indir/infopankki.en-sv.sv | tail -n 500 >| $outdir/test.sv
head -n 11000 $indir/infopankki.en-sv.en | tail -n 500 >| $outdir/test.en

head -n 12000 $indir/infopankki.en-sv.sv | tail -n 1000 >| $outdir/train.1k.sv
head -n 12000 $indir/infopankki.en-sv.en | tail -n 1000 >| $outdir/train.1k.en


