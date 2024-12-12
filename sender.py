from azure.core.credentials import AzureKeyCredential
from azure.ai.formrecognizer import DocumentAnalysisClient, AnalysisFeature
import os
import re
import json
from azure.core.exceptions import HttpResponseError
from groq import Groq
import sys
from firebase_admin import credentials, firestore, initialize_app
from datetime import datetime


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

def extract_text_from_image(photo_path):
    """
    Extracts plain text from the given image using Azure's OCR service.
    
    Args:
        photo_path (str): Path to the image file.
    
    Returns:
        str: Extracted text from the image.
    """
    document_analysis_client = DocumentAnalysisClient(
        endpoint=AZURE_ENDPOINT, credential=AzureKeyCredential(AZURE_KEY)
    )

    with open(photo_path, "rb") as f:
        poller = document_analysis_client.begin_analyze_document(
            "prebuilt-read", document=f
        )
    result = poller.result()

    # Combine text from all lines across all pages
    extracted_text = " ".join(
        line.content for page in result.pages for line in page.lines
    )
    
    return extracted_text.strip()

def analyze_address_with_groq(address_text):
    try:
        os.environ["Api"] = "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"
        apikey = os.environ["Api"]
        client = Groq(api_key=apikey)

        # Sending the request to Groq API to process the address
        completion = client.chat.completions.create(
            model="llama-3.1-70b-versatile",
            messages=[
                {
                    "role": "system",
                    "content": """Identify Address, Pincode, Phone Number, and Name if present.
                    Note: Dont give any other information just provide the asked information in the specified format. 
                    print that in this sequence: Name, PhoneNumber, Address, Pincode.
                    i want the ouput in json format.
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
        print("Response Content:", response_content)

        # Extracting only the JSON part using regex
        json_match = re.search(r'\{.*\}', response_content, re.DOTALL)
        
        if json_match:
            json_str = json_match.group(0)  # Get the matched JSON string
            dic = json.loads(json_str)  # Parse it into a dictionary
            return dic
        else:
            print("No valid JSON found in response.")
    
    except json.JSONDecodeError as e:
        print("Error decoding JSON(llama):", e)
    except Exception as e:
        print("An error occurred(llama):", e)

    return None  # Return None in case of an error

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
        text = extract_text_from_image(photo_path)
        #print(f"Extracted Address: {address}")
        #print(f"Extracted Pincode: {pincode}")

        if not text:
            print("Error: Failed to extract text from the image.")
            sys.exit(1)

        #print("\nAnalyzing with Groq...")
        groq_result = analyze_address_with_groq(text)
        sender_name = groq_result.get('Name')
        sender_phone_number = groq_result.get('PhoneNumber')
        sender_address = groq_result.get('Address')
        sender_pincode = groq_result.get('Pincode')
        
        
        # Prepare data for saving
        sender_data = {
            "photo_path": photo_path,
            "post_id": post_id or "N/A",
            "extracted_data": {
                "text": text
            },
            "groq_analysis": groq_result,
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }

        # Save the sender_data to sender.json
        with open("sender.json", "w") as json_file:
            json.dump(sender_data, json_file, indent=4)

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
