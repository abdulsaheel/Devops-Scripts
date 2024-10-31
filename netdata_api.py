from flask import Flask, jsonify, request
import uuid
import os

app = Flask(__name__)

STREAM_CONF_PATH = "/etc/netdata/stream.conf"

@app.route('/add_child', methods=['POST'])
def add_child():
    # Generate a unique API key
    new_api_key = str(uuid.uuid4())
    
    # Get the public IP from the request data
    child_ip = request.json.get('public_ip', 'unknown')

    # Prepare the entry to add to stream.conf
    conf_entry = f"\n[{new_api_key}]\nenabled = yes  # Child node IP: {child_ip}\n"

    # Append the new entry to stream.conf
    try:
        with open(STREAM_CONF_PATH, 'a') as f:
            f.write(conf_entry)
        
        # Restart Netdata to apply changes
        os.system("sudo systemctl restart netdata")

        return jsonify({"status": "success", "api_key": new_api_key, "child_ip": child_ip}), 201
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
