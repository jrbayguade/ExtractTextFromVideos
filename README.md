🎧 Video Transcription Script (V2.9)
This script automates the extraction and transcription of audio from .mp4 video files.
It uses Whisper by OpenAI to generate .txt transcripts.

🚀 Features
Converts .mp4 files into .mp3 audio

Splits audio into configurable time segments (default: 10 minutes)

Transcribes each segment individually

Allows user confirmation (Y/N) between transcriptions

5-minute cooling pause between segments to reduce CPU heat

Automatically combines all transcripts into a final output.txt

Cleans up temporary files from previous runs automatically

⚙️ Requirements
Linux (tested with Ubuntu via WSL)

ffmpeg installed

🛠️ Usage
bash
Copy
Edit
./convert_MP4_to_TXT.sh [language] [model] [segment_duration]

🛠️ Usage
Parameter | Description | Default
language | Language code for transcription (e.g., en, es, ca) | (none)
model | Whisper model (tiny, base, small, medium, large) | base
segment_duration | Segment length in seconds (e.g., 600 for 10 minutes) | 600

🎛️ Whisper Model Overview
Model | Size | Speed | Accuracy | Recommended for
tiny | ~39MB | 🚀 Very fast | ❌ Low | Quick drafts
base | ~74MB | ⚡ Fast | ❗ Acceptable | Lightweight use
small | ~244MB | ✅ Real-time | ✅ Good | Daily use
medium | ~769MB | 🐢 Slower | 🌟 Very good | Professional
large | ~1.55GB | 🐌 Very slow | 🧠 Best quality | High-end servers

📂 Output
Transcripts are saved as output.txt in the same directory where you launched the script.

If interrupted, a partial output file like output_segment1_segment2.txt will be generated.

⚡ Notes
Whisper requires a lot of RAM for medium and large models. Use tiny, base, or small for better performance on most laptops.

Designed for stability even when run from slow drives (e.g., Dropbox or network folders) by copying files to a temporary Linux filesystem.
