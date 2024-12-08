from flask import Flask, request, jsonify
import os
import subprocess
import threading
import json
import os


app = Flask(__name__)

# Directory to save uploaded photos
UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)  # Create the folder if it doesn't exist




def process_photos(photos):
    """Background processing for the photos."""
    try:
        output = {}
        post_id = None

        # Process photo1 with qr_generate.py
        if '1' in photos:
            combined_script_path = os.path.abspath("qr_generate.py")
            print(f"Executing qr_generate.py with {photos['1']}")
            result_combined = subprocess.run(
                ["python", combined_script_path, photos['1']],
                text=True,
                capture_output=True,
                check=True
            )
            output_combined = result_combined.stdout.strip()
            output['combined_output'] = output_combined

            # Extract post_id from the last line of the output
            try:
                lines = output_combined.split('\n')
                last_line = lines[-1].strip()

                print(f"Last line extracted: {last_line}")

                if last_line.startswith("{") and last_line.endswith("}"):
                    result_data = json.loads(last_line)
                    post_id = result_data.get("post_id")
                    if post_id:
                        print(f"Extracted post_id: {post_id}")
                    else:
                        print("post_id not found in the last line of output.")
                else:
                    print("Last line is not valid JSON.")
            except json.JSONDecodeError as e:
                print(f"Error decoding qr_generate.py output: {e}")
                post_id = None

        # Execute Server.py with post_id and photo2
        if post_id and '2' in photos:
            sender_script_path = os.path.abspath("Server.py")
            print(f"Executing Server.py with {photos['2']} and post_id={post_id}")
            try:
                result_sender = subprocess.run(
                    ["python", sender_script_path, photos['2'], str(post_id)],
                    text=True,
                    capture_output=True,
                    check=True
                )
                output_sender = result_sender.stdout.strip()
                print(f"Server.py output: {output_sender}")
                output['sender_output'] = output_sender
            except subprocess.CalledProcessError as e:
                print(f"Error executing Server.py: {e.stderr}")

        # Execute message.py with post_id and message
        if post_id:
            message_script_path = os.path.abspath("message.py")
            message = "Processing completed for photos"  # Example message
            print(f"Executing message.py with post_id={post_id} and message='{message}'")
            try:
                result_message = subprocess.run(
                    ["python", message_script_path, str(post_id), message],
                    text=True,
                    capture_output=True,
                    check=True
                )
                output_message = result_message.stdout.strip()
                print(f"message.py output: {output_message}")
                output['message_output'] = output_message
            except subprocess.CalledProcessError as e:
                print(f"Error executing message.py: {e.stderr}")

        print(f"Photo processing completed with output: {output}")

    except Exception as e:
        print(f"Error in background processing: {e}")





@app.route("/upload", methods=["POST"])
def upload_photo():
    print("Received a request to /upload")

    # Initialize a dictionary to store photo paths and IDs
    photos = {}
    responses = []

    # Check and process 'photo1' and 'id1'
    if "photo1" in request.files:
        photo1 = request.files['photo1']
        id1 = request.form.get('id1')
        if not id1:
            print("Missing id1 for photo1")
            responses.append({"error": "Missing id1 for photo1"})
        else:
            photo1_path = os.path.join(UPLOAD_FOLDER, photo1.filename)
            photo1.save(photo1_path)
            photos['1'] = photo1_path
            print(f"Saved photo1 at: {photo1_path}")
            responses.append({"message": "photo1 uploaded successfully", "photo1_path": photo1_path})
    else:
        print("No photo1 part in the request")
        responses.append({"error": "No photo1 part in the request"})

    # Check and process 'photo2' and 'id2' if present
    if "photo2" in request.files:
        photo2 = request.files['photo2']
        id2 = request.form.get('id2')
        if not id2:
            print("Missing id2 for photo2")
            responses.append({"error": "Missing id2 for photo2"})
        else:
            photo2_path = os.path.join(UPLOAD_FOLDER, photo2.filename)
            photo2.save(photo2_path)
            photos['2'] = photo2_path
            print(f"Saved photo2 at: {photo2_path}")
            responses.append({"message": "photo2 uploaded successfully", "photo2_path": photo2_path})
    else:
        print("No photo2 part in the request")
        responses.append({"error": "No photo2 part in the request"})

    # Respond immediately after upload
    response = {"message": "Photos uploaded successfully", "uploads": responses}
    if photos:
        # Start a thread to process the photos in the background
        threading.Thread(target=process_photos, args=(photos,)).start()

    return jsonify(response), 200


@app.route("/")
def home():
    return "Flask server is running! Use the /upload endpoint to upload photos."


if __name__ == "__main__":
    app.run(debug=True)