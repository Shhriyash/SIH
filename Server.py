from azure.core.credentials import AzureKeyCredential
from azure.ai.formrecognizer import DocumentAnalysisClient, AnalysisFeature
import os
import re
import json
from azure.core.exceptions import HttpResponseError
from groq import Groq
import sys
from firebase_admin import credentials, firestore, initialize_app

# Azure OCR settings
AZURE_ENDPOINT = "https://ocr-for-posts.cognitiveservices.azure.com/"
AZURE_KEY = "G0011GMGd40PX2lNQTgVqJlUIwJvwq9Q1y5k7xEdEAPwsoE0i1yxJQQJ99AKACGhslBXJ3w3AAALACOG7tRL"

# Groq API settings
os.environ["Api"] = "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"
GROQ_API_KEY = os.environ["Api"]

# Initialize Firestore client
cred = credentials.Certificate("dakmadad-sih-firebase-adminsdk-pczek-6e05d2a574.json")
initialize_app(cred)
db = firestore.client()

def upload_to_firestore(post_id, data):
    try:
        doc_ref = db.collection("post_details").document(post_id)
        doc_ref.set({"sender_details": data}, merge=True)
        print(f"Data uploaded successfully for post_id: {post_id}")
    except Exception as e:
        print(f"Error uploading data to Firestore: {e}")

def extract_address_and_pincode_from_image(photo_path):
    document_analysis_client = DocumentAnalysisClient(
        endpoint=AZURE_ENDPOINT, credential=AzureKeyCredential(AZURE_KEY)
    )

    with open(photo_path, "rb") as f:
        poller = document_analysis_client.begin_analyze_document(
            "prebuilt-read", document=f, features=[AnalysisFeature.LANGUAGES]
        )
    result = poller.result()

    address_info = {"address": "", "word_confidence_score": {}}
    for page in result.pages:
        for line in page.lines:
            address_info["address"] += f" {line.content}"
            for word in line.get_words():
                address_info["word_confidence_score"][word.content] = word.confidence

    # Extract pincode
    pincode = next(
        (word for word in address_info["word_confidence_score"] if re.fullmatch(r"\d{6}", word)),
        None
    )
    return address_info["address"].strip(), pincode

def analyze_address_with_groq(address_text):
    client = Groq(api_key=GROQ_API_KEY)
    completion = client.chat.completions.create(
        model="llama-3.1-70b-versatile",
        messages=[
            {
                "role": "system",
                "content": """Identify Address, Pincode, Phone Number, and Name if present.
                    Note: Dont give any other information just provide the asked information in the specified format. 
                    print that in this sequence: Name, PhoneNumber, Address, Pincode.
                    i want the output in json format.
                    """
            },
            {
                "role": "user",
                "content": address_text
            }
        ],
        temperature=1,
        max_tokens=1024,
        top_p=1,
        stream=True,
        stop=None,
    )

    response_content = ""
    for chunk in completion:
        if chunk.choices[0].delta.content:  # Check for valid content
            response_content += chunk.choices[0].delta.content

    # Debug: Print full response content before parsing
    #print("Response Content from Groq:", response_content)
    return json.loads(response_content)

def main():
    if len(sys.argv) < 2:
        print("Error: Please provide the photo path as an argument!")
        sys.exit(1)

    photo_path = sys.argv[1]
    post_id = sys.argv[2] if len(sys.argv) > 2 else None  # Optional second argument

    if not os.path.exists(photo_path):
        print(f"Error: The file {photo_path} does not exist.")
        sys.exit(1)

    # Print the provided post_id
    if post_id:
        print(f"Received post_id: {post_id}")
    else:
        print("No post_id provided. Proceeding without it.")

    try:
        #print("Extracting address and pincode from image...")
        address, pincode = extract_address_and_pincode_from_image(photo_path)
        #print(f"Extracted Address: {address}")
        #print(f"Extracted Pincode: {pincode}")

        if not address or not pincode:
            print("Error: Failed to extract address or pincode from the image.")
            sys.exit(1)

        #print("\nAnalyzing with Groq...")
        groq_result = analyze_address_with_groq(address)
        #print("Groq Analysis Result:")
        #print(json.dumps(groq_result, indent=4))

        # Upload to Firestore
        if post_id:
            upload_to_firestore(post_id, groq_result)
        else:
            print("No post_id provided. Data not uploaded to Firestore.")
    except HttpResponseError as error:
        print("Azure OCR Error:", error)
    except Exception as e:
        print("Unexpected Error:", e)

if __name__ == "__main__":
    main()
