#!/bin/sh
# Runs on container startup to generate files and dynamic HTML

FILES_DIR="/usr/share/nginx/html/files"
mkdir -p "$FILES_DIR"

echo "Generating test files (this might take a moment)..."

# Generate a 1MB entropic seed file to duplicate (faster than reading urandom for 1GB)
dd if=/dev/urandom of=/tmp/seed.bin bs=1M count=1 2>/dev/null

generate_file() {
    local name=$1
    local mb_size=$2
    local target="$FILES_DIR/$name"

    if [ ! -f "$target" ]; then
        echo "Generating $name..."
        if [ "$mb_size" = "0" ]; then
            dd if=/tmp/seed.bin of="$target" bs=128K count=1 2>/dev/null
        else
            # Concatenate the 1MB seed multiple times to reach the desired size
            for i in $(seq 1 $mb_size); do
                cat /tmp/seed.bin >> "$target"
            done
        fi
    fi
}

generate_file "128KB.txt" 0
generate_file "1MB.txt" 1
generate_file "10MB.txt" 10
generate_file "100MB.txt" 100
generate_file "500MB.txt" 500
generate_file "1GB.txt" 1024

# Generate index.html dynamically to capture the container's hostname and IP
HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -i | awk '{print $1}')

cat <<EOF > /usr/share/nginx/html/index.html
<html>
    <head>
        <title>High-Performance Load Tester</title>
        <style>
            body { font-family: sans-serif; padding: 20px; background-color: #f4f4f4; line-height: 1.6; }
            .card { background: white; border: 1px solid #ddd; padding: 20px; border-radius: 8px; max-width: 900px; margin: 0 auto; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            h1 { color: #2c3e50; text-align: center; border-bottom: 2px solid #eee; padding-bottom: 10px; }
            h3 { margin-top: 30px; color: #007bff; }
            table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 0.9em; }
            th, td { text-align: left; padding: 10px; border-bottom: 1px solid #eee; }
            th { background-color: #f8f9fa; }
            .cmd { background: #333; color: #0f0; padding: 4px 8px; border-radius: 4px; font-family: monospace; font-size: 0.85em; display: inline-block; }
            .note { background: #e7f3fe; border-left: 5px solid #2196F3; padding: 10px; font-size: 0.9em; margin: 15px 0; }
            .sys-info { text-align: center; background: #fafafa; padding: 10px; border-radius: 5px; margin-bottom: 20px; }
        </style>
    </head>
    <body>
        <div class="card">
            <h1>High-Performance Load Tester (Nginx)</h1>
            <div class="sys-info">
                <strong>Container ID:</strong> $HOSTNAME &nbsp;|&nbsp; 
                <strong>Internal IP:</strong> $IP_ADDRESS
            </div>
            <div class="note">
                <strong>How to test bandwidth:</strong> Use the commands below to download files. 
                We send the output to <code>/dev/null</code> so you only measure network speed, not disk write speed.
            </div>
            <h3>Available Test Files</h3>
            <table>
                <thead>
                    <tr><th>File</th><th>Size</th><th>Test Command (Linux/Mac)</th></tr>
                </thead>
                <tbody>
                    <tr><td><a href="/files/128KB.txt">128KB.txt</a></td><td>0.12 MB</td><td><code class="cmd">wget -O /dev/null http://$IP_ADDRESS:5000/files/128KB.txt</code></td></tr>
                    <tr><td><a href="/files/1MB.txt">1MB.txt</a></td><td>1.00 MB</td><td><code class="cmd">wget -O /dev/null http://$IP_ADDRESS:5000/files/1MB.txt</code></td></tr>
                    <tr><td><a href="/files/10MB.txt">10MB.txt</a></td><td>10.00 MB</td><td><code class="cmd">wget -O /dev/null http://$IP_ADDRESS:5000/files/10MB.txt</code></td></tr>
                    <tr><td><a href="/files/100MB.txt">100MB.txt</a></td><td>100.00 MB</td><td><code class="cmd">wget -O /dev/null http://$IP_ADDRESS:5000/files/100MB.txt</code></td></tr>
                    <tr><td><a href="/files/500MB.txt">500MB.txt</a></td><td>500.00 MB</td><td><code class="cmd">wget -O /dev/null http://$IP_ADDRESS:5000/files/500MB.txt</code></td></tr>
                    <tr><td><a href="/files/1GB.txt">1GB.txt</a></td><td>1024.00 MB</td><td><code class="cmd">wget -O /dev/null http://$IP_ADDRESS:5000/files/1GB.txt</code></td></tr>
                </tbody>
            </table>
        </div>
    </body>
</html>
EOF
