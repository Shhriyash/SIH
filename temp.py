import sys
import requests
import sqlite3
import math
import json
import re
from azure.core.credentials import AzureKeyCredential
from azure.ai.formrecognizer import DocumentAnalysisClient, AnalysisFeature
from azure.core.exceptions import HttpResponseError
from groq import Groq
import os

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

# Function to extract address, pincode, phone number, and name using Groq





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


# Main execution flow
if __name__ == "__main__":
    try:
        # Fetch photo path from command-line arguments
        try:
            if len(sys.argv) < 2:
                print("Error: Please provide a photo path!")
                sys.exit(1)

            # Fetch the photo path from command-line arguments
            photo_path = sys.argv[1]
            print(f"Processing photo: {photo_path}")

            # Check if the provided path exists
            if not os.path.exists(photo_path):
                raise FileNotFoundError(f"No such file or directory: {photo_path}")

            # Replace this with actual processing logic
            print("Photo processed successfully.")

        except Exception as e:
            print(f"Error: {e}")
        
        # Step 1: Extract address using Azure Form Recognizer
        address = process_photo(photo_path)
        #print("\nExtracted Address:", address)
        
        # Step 2: Extract structured details from address using Groq
        address_details = extract_address_details(address)
        # print("\nExtracted Address Details:", type(address_details))
        
        name = address_details.get('Name')
        phone_number = address_details.get('PhoneNumber')
        address = address_details.get('Address')
        pincode = address_details.get('Pincode')    

        # Output the stored variables
        
        

        # Step 3: Use extracted address as input for geocoding and find nearest post office
        with open("credentials.json", "r") as file:
            credentials = json.load(file)
        
        api_key = credentials["google_api_key"]

        geocoded_info = geocode_address(api_key, address)
        if "error" in geocoded_info:
            print("\nGeocoding failed:", geocoded_info["error"])
        else:
    # Storing the response in variables
            formatted_address = geocoded_info.get('formattedAddress')
            latitude = geocoded_info.get('latitude')
            longitude = geocoded_info.get('longitude')
            pincode = geocoded_info.get('pincode')
            city = geocoded_info.get('city')
            state = geocoded_info.get('state')

            # Print the stored variables
            
            print("\nGoogle Maps Link for Geocoded Location:")
            link = create_google_maps_link(latitude,longitude)
            print(link)

            nearest_post_office = find_nearest_post_office(api_key, pincode, address)
            if "error" in nearest_post_office:
                print("\nError:", nearest_post_office["error"])
            else:
                po_name = nearest_post_office.get('name')
                po_pincode = nearest_post_office.get('pincode')
                po_delivery_type = nearest_post_office.get('delivery_type')
                po_state = nearest_post_office.get('state')
                po_latitude = nearest_post_office.get('latitude')
                po_longitude = nearest_post_office.get('longitude')
                po_office_type = nearest_post_office.get('office_type')


        print("Name:", name)
        print("Phone Number:", phone_number)
        print("Address:", address)
        print("Pincode:", pincode)   
        print(f"Formatted Address: {formatted_address}")
        print(f"Latitude: {latitude}")
        print(f"Longitude: {longitude}")
        print(f"Pincode: {pincode}")
        print(f"City: {city}")
        print(f"State: {state}")
        print(f"Nme: {po_name}")
        print(f"Pincode: {po_pincode}")
        print(f"Delivery: {po_delivery_type}")
        print(f"State: {po_state}")
        print(f"Latitude: {po_latitude}")
        print(f"Longitude: {po_longitude}")
        print(f"Office Type: {po_office_type}") 
    except Exception as e:
        print("Error:", str(e))
