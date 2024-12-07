import sys
import requests
import sqlite3
import math
import json
import re
import time
from datetime import datetime
from firebase_admin import credentials, firestore, initialize_app
from azure.core.credentials import AzureKeyCredential
from azure.ai.formrecognizer import DocumentAnalysisClient, AnalysisFeature
from azure.core.exceptions import HttpResponseError
from groq import Groq
import os
import qrcode
from PIL import Image, ImageDraw, ImageFont

# Initialize Firebase Admin SDK
cred = credentials.Certificate("dakmadad-sih-firebase-adminsdk-pczek-6e05d2a574.json")
initialize_app(cred)
db = firestore.client()

# Haversine formula to calculate the distance between two points on the Earth
def haversine(lat1, lon1, lat2, lon2):
    R = 6371.0  # Radius of the Earth in kilometers
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = math.sin(dlat / 2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

# Function to fetch post offices by pincode from the database
def fetch_post_offices_by_pincode(pincode):
    conn = sqlite3.connect('post_office.db')
    cursor = conn.cursor()
    cursor.execute("""
        SELECT OfficeName, Pincode, Delivery, StateName, Latitude, Longitude, OfficeType 
        FROM PostOfficeDetails WHERE Pincode = ?
    """, (pincode,))
    post_offices = cursor.fetchall()
    conn.close()

    post_offices_list = []
    for row in post_offices:
        latitude = float(row[4]) if row[4] is not None else None
        longitude = None
        if row[5] is not None:
            longitude_str = str(row[5])
            if longitude_str.replace('.', '', 1).replace('-', '', 1).isdigit():
                longitude = float(longitude_str)
        
        if latitude is not None and longitude is not None:
            post_offices_list.append({
                "name": row[0],
                "pincode": row[1],
                "delivery_type": row[2],
                "state": row[3],
                "latitude": latitude,
                "longitude": longitude,
                "office_type": row[6]
            })
    return post_offices_list

# Function to geocode an address using Google Geocoding API
def geocode_address(api_key, address):
    url = "https://maps.googleapis.com/maps/api/geocode/json"
    params = {"address": address, "key": api_key}
    response = requests.get(url, params=params)
    if response.status_code == 200:
        data = response.json()
        if data.get("results"):
            result = data["results"][0]
            geometry = result["geometry"]
            address_components = result["address_components"]

            output = {
                "formattedAddress": result.get("formatted_address", ""),
                "latitude": geometry["location"]["lat"],
                "longitude": geometry["location"]["lng"],
                "pincode": "",
                "city": "",
                "state": ""
            }
            for component in address_components:
                if "locality" in component.get("types", []):
                    output["city"] = component["long_name"]
                if "administrative_area_level_1" in component.get("types", []):
                    output["state"] = component["long_name"]
                if "postal_code" in component.get("types", []):
                    output["pincode"] = component["long_name"]
            return output
    return {"error": f"Geocoding failed: {response.status_code}"}

# Function to find the nearest post office to a given address
def find_nearest_post_office(api_key, pc, address):
    geocoded_info = geocode_address(api_key, address)
    if "error" in geocoded_info:
        return geocoded_info
    
    lat, lon, pincode = geocoded_info["latitude"], geocoded_info["longitude"], geocoded_info["pincode"]
    post_offices = fetch_post_offices_by_pincode(pc)

    if not post_offices:
        return {"error": "No post offices found for the given pincode"}
    
    nearest_post_office = None
    min_distance = float('inf')

    for post_office in post_offices:
        distance = haversine(lat, lon, post_office["latitude"], post_office["longitude"])
        if distance < min_distance:
            min_distance = distance
            nearest_post_office = post_office

    return nearest_post_office if nearest_post_office else {"error": "No nearest post office found"}

# Function to create a Google Maps link for a location
def create_google_maps_link(latitude, longitude):
    return f"https://www.google.com/maps?q={latitude},{longitude}"

# Azure Form Recognizer to extract address from a photo
def process_photo(photo_path):
    endpoint = "https://ocr-for-posts.cognitiveservices.azure.com/"
    key = "G0011GMGd40PX2lNQTgVqJlUIwJvwq9Q1y5k7xEdEAPwsoE0i1yxJQQJ99AKACGhslBXJ3w3AAALACOG7tRL"  # Replace with your actual key

    document_analysis_client = DocumentAnalysisClient(
        endpoint=endpoint, credential=AzureKeyCredential(key)
    )

    with open(photo_path, "rb") as f:
        poller = document_analysis_client.begin_analyze_document(
            "prebuilt-read", document=f, features=[AnalysisFeature.LANGUAGES]
        )
    result = poller.result()

    address = ""
    for page in result.pages:
        for line in page.lines:
            address += line.content + " "

    return address.strip()

def extract_address_details(address):
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
                    "content": address
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
        print("Error decoding JSON:", e)
    except Exception as e:
        print("An error occurred:", e)

    return None  # Return None in case of an error


# Function to generate unique post_id
def generate_unique_post_id():
    timestamp = int(time.time() * 1000)
    return str(timestamp)[:12]

# Function to upload data to Firestore
def upload_to_firestore(post_id, data):
    try:
        db.collection("post_details").document(post_id).set(data)
        print(f"Data uploaded successfully with post_id: {post_id}")
    except Exception as e:
        print(f"Error uploading data to Firestore: {e}")
        
def generate_qr_code(data, pincode, nearest_post_office, output_path="qr_code.png"):
    try:
        # Generate the QR code
        qr = qrcode.make(data)
        
        # Prepare font settings
        font_path = "conthrax\Conthrax-SemiBold.otf"  # Adjust based on your system
        font_size = 18  # Adjust font size
        try:
            font = ImageFont.truetype(font_path, font_size)
        except IOError:
            raise Exception("Font file not found. Adjust the font_path variable.")

        # Create a new image with space for text above the QR code
        qr_width, qr_height = qr.size
        text_height = 60  # Space for text
        canvas_height = qr_height + text_height
        new_img = Image.new("RGB", (qr_width, canvas_height), "white")

        # Draw text onto the canvas
        draw = ImageDraw.Draw(new_img)
        text = f"Pincode: {pincode}\nNearest Post Office: {nearest_post_office}"
        text_x = 10  # Margin from left
        text_y = 10  # Margin from top
        draw.text((text_x, text_y), text, fill="black", font=font)

        # Paste the QR code below the text
        new_img.paste(qr, (0, text_height))

        # Save the final image
        new_img.save(output_path)
        print(f"QR code with text generated and saved as {output_path}")
    except Exception as e:
        print(f"Error generating QR code: {e}")
        

# Main execution flow
if __name__ == "__main__":
    try:
        # Fetch photo path from command-line arguments
        if len(sys.argv) < 2:
            print("Error: Please provide a photo path!")
            sys.exit(1)

        photo_path = sys.argv[1]

        if not os.path.exists(photo_path):
            raise FileNotFoundError(f"No such file or directory: {photo_path}")

        # Extract address from photo
        address = process_photo(photo_path)

        # Extract structured details
        address_details = extract_address_details(address)
        name = address_details.get('Name')
        phone_number = address_details.get('PhoneNumber')
        address = address_details.get('Address')
        pincode = address_details.get('Pincode')

        # Geocode and find nearest post office
        with open("credentials.json", "r") as file:
            credentials = json.load(file)
        
        api_key = credentials["google_api_key"]
        geocoded_info = geocode_address(api_key, address)
        if "pincode" in geocoded_info:
            rpincode = geocoded_info["pincode"]
            print("Pincode:", pincode)
        if "formattedAddress" in geocoded_info:
            raddress = geocoded_info["formattedAddress"]
            print("formattedAddress:", raddress)   
            
        nearest_post_office = find_nearest_post_office(api_key, rpincode, raddress)
        nearpo = nearest_post_office.get("name", "Unknown")
        nearpc = nearest_post_office.get("pincode", "Unknown")
        # Generate unique post_id
        
        print(nearpo, nearpc)
        post_id = generate_unique_post_id()

        # Prepare data for Firestore
        data = {
            "receiver_details": {
                "post_id": post_id,
                "name": name,
                "phone_number": phone_number,
                "address": address
            },
            "geocoded_info": geocoded_info,
            "nearest_post_office": nearest_post_office,
            "status": 'scanned',
            "updated_at": datetime.now(),
            "curr_post_office_name": ' '
        }

        # Upload to Firestore
        upload_to_firestore(post_id, data)
        
        qr_data = {
            "post_id": post_id,
            "geocoded_info": geocoded_info
        }
        qr_data_json = json.dumps(qr_data)

        # Generate QR code and save as PNG file
        output_path = f"{post_id}.png"  # Save the QR code as {post_id}.png
        generate_qr_code(qr_data_json, nearpc, nearpo, output_path)
        
        print(json.dumps({"post_id": post_id}))
        sys.exit(0)  # Clean exit
        
    except Exception as e:
        print("Error:", str(e))
        sys.exit(1)  # Error exit
