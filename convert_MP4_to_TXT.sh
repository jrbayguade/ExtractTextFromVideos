#!/bin/bash

# =====================================================
echo ""
echo "🧠 Script: Video Transcription V2.9 (split audio segments, user-controlled)"
echo "🗓️ Date: $(date)"
echo "======================================================"

# Parse parameters
LANGUAGE=$1
MODEL=$2
SEGMENT_DURATION=${3:-600}  # Default to 600 seconds (10 minutes)
MODEL=${MODEL:-base}

# Display usage and Whisper model summary
echo "ℹ️  USAGE: ./convert_MP4_to_TXT.sh [language] [model] [segment_duration]"
echo "📌 Example: ./convert_MP4_to_TXT.sh es base 600"
echo ""
echo "🎛️ Models available:"
echo " - tiny   (~39MB):     very fast, low accuracy"
echo " - base   (~74MB):     fast, acceptable quality (default)"
echo " - small  (~244MB):    good quality"
echo " - medium (~769MB):    high quality"
echo " - large  (~1.55GB):   best quality, slowest (needs lots of RAM)"
echo "======================================================"

# Check if whisper is installed
if ! command -v whisper &> /dev/null; then
    echo "❌ Whisper is not in PATH. Add ~/.local/bin to your PATH and try again."
    exit 1
fi

# Cleanup temp folders from previous runs
echo "🧹 Cleaning up old temporary folders..."
CLEANED=$(find /tmp -maxdepth 1 -type d -name 'transcribe-*' -print -exec rm -rf {} + 2>/dev/null)
if [[ -n "$CLEANED" ]]; then
  echo "✅ Removed previous temp folders:"
  echo "$CLEANED"
else
  echo "✅ No previous temp folders found."
fi

# Prepare workspace
ORIG_DIR=$(pwd)
TMP_DIR=$(mktemp -d -t transcribe-XXXXXXXX)
mkdir -p "$TMP_DIR/tmp_audio" "$TMP_DIR/tmp_segments" "$TMP_DIR/tmp_transcripts"

echo "📂 Working in: $TMP_DIR"
echo "📥 Copying .mp4 files from: $ORIG_DIR"
cp "$ORIG_DIR"/*.mp4 "$TMP_DIR/" || { echo "❌ No .mp4 files found."; exit 1; }

cd "$TMP_DIR" || exit 1

FILES=( *.mp4 )
COUNT=1
FRAGMENT_NAMES=()

for f in "${FILES[@]}"; do
  base="${f%.mp4}"
  echo ""
  echo "🎧 Extracting audio from: $f"
  ffmpeg -loglevel error -i "$f" -q:a 0 -map a "tmp_audio/$base.mp3" || continue

  echo "✂️ Splitting $base.mp3 into segments of $SEGMENT_DURATION seconds..."
  ffmpeg -loglevel error -i "tmp_audio/$base.mp3" -f segment -segment_time "$SEGMENT_DURATION" -c copy "tmp_segments/${base}_%03d.mp3"

  SEGMENTS=( tmp_segments/${base}_*.mp3 )
  SEG_COUNT=1

  for seg in "${SEGMENTS[@]}"; do
    seg_base=$(basename "$seg" .mp3)
    echo ""
    echo "📝 Transcribing segment [$SEG_COUNT/${#SEGMENTS[@]}]: $seg_base"
    echo "   Started at: $(date)"

    CMD=( whisper "$seg" --task transcribe --output_format txt --output_dir tmp_transcripts )
    [[ $LANGUAGE ]] && CMD+=( --language "$LANGUAGE" )
    [[ $MODEL ]] && CMD+=( --model "$MODEL" )
    "${CMD[@]}" || { echo "❌ Whisper failed on $seg"; continue; }

    FRAGMENT_NAMES+=("$seg_base")
    SEG_COUNT=$((SEG_COUNT + 1))

    echo ""
    echo "❓ Continue with next segment? (Y/N)"
    read -r answer
    if [[ "$answer" != "Y" && "$answer" != "y" ]]; then
      echo ""
      echo "📄 Combining partial transcriptions..."
      OUT_NAME="output_$(IFS=_; echo "${FRAGMENT_NAMES[*]}").txt"
      > "$TMP_DIR/$OUT_NAME"
      for txt in tmp_transcripts/*.txt; do
        name=$(basename "$txt" .txt)
        [[ " ${FRAGMENT_NAMES[*]} " == *" $name "* ]] || continue
        echo "------------------------------" >> "$TMP_DIR/$OUT_NAME"
        echo "File: $name - Date: $(date)" >> "$TMP_DIR/$OUT_NAME"
        echo "------------------------------" >> "$TMP_DIR/$OUT_NAME"
        cat "$txt" >> "$TMP_DIR/$OUT_NAME"
        echo "" >> "$TMP_DIR/$OUT_NAME"
      done
      cp "$TMP_DIR/$OUT_NAME" "$ORIG_DIR/"
      echo "📂 Partial output saved as: $ORIG_DIR/$OUT_NAME"
      cd "$ORIG_DIR" && rm -rf "$TMP_DIR"
      exit 0
    fi

    echo "🧊 Cooling down for 5 minutes..."
    sleep 300
  done
  COUNT=$((COUNT + 1))
done

FINAL_NAME="output.txt"
echo ""
echo "📄 Combining all segment transcriptions into $FINAL_NAME..."
> "$TMP_DIR/$FINAL_NAME"
for txt in tmp_transcripts/*.txt; do
  echo "------------------------------" >> "$TMP_DIR/$FINAL_NAME"
  echo "File: $(basename "$txt") - Date: $(date)" >> "$TMP_DIR/$FINAL_NAME"
  echo "------------------------------" >> "$TMP_DIR/$FINAL_NAME"
  cat "$txt" >> "$TMP_DIR/$FINAL_NAME"
  echo "" >> "$TMP_DIR/$FINAL_NAME"
done

cp "$TMP_DIR/$FINAL_NAME" "$ORIG_DIR/" || { echo "❌ Failed to copy output.txt"; exit 1; }
cd "$ORIG_DIR" && rm -rf "$TMP_DIR"

echo ""
echo "✅ Done! Final transcript saved as: $ORIG_DIR/$FINAL_NAME"
echo "🕒 Completed at: $(date)"
echo "======================================================"
echo ""
