# this file will show you how to run inference to play with basic yes no model
# with your own data

train_cmd="utils/run.pl"
decode_cmd="utils/run.pl"
mfcc_dir="mfcc_inference"

# 0. record your own audio
arecord -d  -f S16_LE data/inference/test.wav

# 1. compute mfcc of test audio file
steps/make_mfcc.sh --nj 1 --cmd "$train_cmd" data/inference exp/make_mfcc/inference $mfccdir

# 2. compute cmvn.scp files
steps/compute_cmvn_stats.sh data/inference exp/make_mfcc/inference $mfccdir

# 3. decoding stage
# Decoding
steps/decode.sh --nj 1 --cmd "$decode_cmd" \
    exp/mono0a/graph_tgpr data/inference exp/mono0a/inference
