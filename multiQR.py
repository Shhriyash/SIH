import firebase_admin
from firebase_admin import credentials, firestore
from flask import Flask, jsonify, request, redirect

# Initialize Firebase Admin SDK with service account credentials
cred = credentials.Certificate("dakmadad-sih-firebase-adminsdk-pczek-6e05d2a574.json")
firebase_admin.initialize_app(cred)

# Initialize Firestore client
db = firestore.client()

# Initialize Flask app
app = Flask(__name__)

@app.route('/check_delivery', methods=['GET'])
def check_delivery():
    # Get post_id from query parameters
    post_id = request.args.get('post_id')
    
    if not post_id:
        return jsonify({"error": "post_id is required"}), 400
    
    # Fetch document from Firestore using post_id
    try:
        doc_ref = db.collection("post_details").document(post_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            return jsonify({"error": "Post not found"}), 404
        
        # Get the 'isDelivered' status
        is_delivered = doc.to_dict().get('isDelivered', None)
        
        if is_delivered is None:
            return jsonify({"error": "isDelivered field not found"}), 404
        
        # Redirect based on the isDelivered status
        if is_delivered:
            return redirect("https://f655-49-249-229-42.ngrok-free.app/check_delivery173392836097")
        else:
            return redirect("")
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
