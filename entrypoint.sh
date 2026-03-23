#!/bin/bash
set -e

# Generate files cleanly before Uvicorn starts
python -c "import main; main.generate_files()"

# Launch Uvicorn with 4 workers to handle high concurrency
exec uvicorn main:app --host 0.0.0.0 --port 5000 --workers 4 --loop uvloop --http httptools
