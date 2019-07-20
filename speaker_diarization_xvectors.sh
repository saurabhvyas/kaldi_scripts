# kaldi commit id : commit b5385b46c135f8d1f2bf4f9924e287e6fd91cd23 
# pretrained model used : http://kaldi-asr.org/models/m3
# this script should be executed from egs/callhome_diarization/v2 directory
# create your own data directory at the above directory and call it speaker_diarization, it should follow the general kaldi style format, eg. create and train folder etc.



# 0. use the same config files as provided in the pretrained model folder, or will fail in later stages


# 1. compute mfcc features , note that we need to create mfcc config file 
train_cmd="utils/run.pl"
data_dir="speaker_diarization/data/train"
log_dir="speaker_diarization/exp/make_mfcc"

sudo steps/make_mfcc.sh --nj 1 --cmd "$train_cmd" --mfcc-config speaker_diarization/conf/mfcc.conf "$data_dir" "$log_dir"


# 2 . compute vad decisions file
log_dir="speaker_diarization/exp/make_vad"

sudo bash  steps/compute_vad_decision.sh --nj 1 --vad-config speaker_diarization/conf/vad.conf "$data_dir" "$log_dir"

#3 create segmented data
sudo bash ../v1/diarization/vad_to_segments.sh --nj 1 --cmd "$train_cmd" "$data_dir" speaker_diarization/data/train_segmented

# 3. cmvn feature extraction
data_dir="speaker_diarization/data/train_segmented"
output_dir="speaker_diarization/data/train_segmented"
log_dir="speaker_diarization/exp/cmvn"

sudo bash /home/saurabh/Documents/kaldi/egs/callhome_diarization/v2/local/nnet3/xvector/prepare_feats.sh --nj 1 --cmd "$train_cmd" "$data_dir" "$output_dir" "$log_dir"


# 4. extract xvectors
nnet_dir="/home/saurabh/Documents/kaldi/egs/callhome_diarization/v2/0003_sre16_v2_1a/exp/xvector_nnet_1a"
log_dir="$nnet_dir/exp/xvectors"

sudo diarization/nnet3/xvector/extract_xvectors.sh --cmd \ "$train_cmd --mem 5G" \
--nj 1 --window 1.5 --period 0.75 --apply-cmn false \
--min-segment 0.5 $nnet_dir \
 "$data_dir" "$log_dir"


# 5. plda scoring
plda_dir="/home/saurabh/Documents/kaldi/egs/callhome_diarization/v2/0003_sre16_v2_1a/exp/xvectors_sre_combined"

sudo diarization/nnet3/xvector/score_plda.sh \
--cmd "$train_cmd --mem 4G" \
--target-energy 0.9 --nj 4 "$plda_dir" \
$nnet_dir/exp/xvectors $nnet_dir/xvectors/plda_scores


# 6. final clustering step
threshold=0.5

sudo diarization/cluster.sh --cmd "$train_cmd --mem 4G" --nj 1 \
--threshold $threshold \
$nnet_dir/xvectors/plda_scores \
$nnet_dir/xvectors/plda_scores_speakers


