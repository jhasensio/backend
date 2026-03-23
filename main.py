import os
import socket
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, FileResponse

app = FastAPI()

FILES_DIR = "static_files"
SIZES = {
    "128KB.txt": 128 * 1024,
    "1MB.txt": 1 * 1024 * 1024,
    "10MB.txt": 10 * 1024 * 1024,
    "100MB.txt": 100 * 1024 * 1024,
    "500MB.txt": 500 * 1024 * 1024,
    "1GB.txt": 1 * 1024 * 1024 * 1024
}

def generate_files():
    """Generates test files with entropic data to bypass network compression."""
    if not os.path.exists(FILES_DIR):
        os.makedirs(FILES_DIR)
        
    print("Checking/Generating entropic test files...")
    chunk_size = 1024 * 1024 # 1MB
    random_chunk = os.urandom(chunk_size)
    
    for filename, size_bytes in SIZES.items():
        filepath = os.path.join(FILES_DIR, filename)
        if not os.path.exists(filepath):
            print(f"Generating {filename}...")
            with open(filepath, "wb") as f:
                bytes_written = 0
                while bytes_written < size_bytes:
                    remaining = size_bytes - bytes_written
                    write_size = min(chunk_size, remaining)
                    f.write(random_chunk if write_size == chunk_size else random_chunk[:write_size])
                    bytes_written += write_size

@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    hostname = socket.gethostname()
    ip_address = socket.gethostbyname(hostname)
    
    file_rows = ""
    for filename, size in SIZES.items():
        file_rows += f"""
        <tr>
            <td><a href="/files/{filename}">{filename}</a></td>
            <td>{size / (1024 * 1024):.2f} MB</td>
            <td><code class="cmd">wget -O /dev/null http://{ip_address}:5000/files/{filename}</code></td>
        </tr>
        """

    # Dynamically extract and render the HTTP headers
    headers_html = "<br>".join([f"<strong>{k}:</strong> {v}" for k, v in request.headers.items()])

    style = """
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
    """

    return f"""
    <html>
        <head><title>Bandwidth & Load Tester</title><style>{style}</style></head>
        <body>
            <div class="card">
                <h1>Network Load Tester</h1>
                <div class="sys-info">
                    <strong>Container ID:</strong> {hostname} &nbsp;|&nbsp; 
                    <strong>Internal IP:</strong> {ip_address}
                </div>
                <div class="note">
                    <strong>How to test bandwidth:</strong> Use the commands below to download files. 
                    We send the output to <code>/dev/null</code> so you only measure network speed.
                </div>
                
                <h3>Header Debug (Live)</h3>
                <div style="font-family: monospace; background: #eee; padding: 10px; max-height: 200px; overflow-y: auto; border-left: 4px solid #333;">
                    {headers_html}
                </div>

                <h3>Available Test Files</h3>
                <table>
                    <thead>
                        <tr><th>File</th><th>Size</th><th>Test Command</th></tr>
                    </thead>
                    <tbody>{file_rows}</tbody>
                </table>
            </div>
        </body>
    </html>
    """

@app.get("/files/{filename}")
async def serve_files(filename: str):
    file_path = os.path.join(FILES_DIR, filename)
    if os.path.exists(file_path):
        return FileResponse(file_path, media_type='application/octet-stream', filename=filename)
    return {"error": "File not found"}
