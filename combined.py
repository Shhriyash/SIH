import sys
import requests
import sqlite3
import math
import json
import re
import os
from azure.core.credentials import AzureKeyCredential
from azure.ai.formrecognizer import DocumentAnalysisClient, AnalysisFeature
from azure.core.exceptions import HttpResponseError

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
    return {"error": "Geocoding failed"}

# Function to find the nearest post office to a given address
def find_nearest_post_office(api_key, address):
    geocoded_info = geocode_address(api_key, address)
    if "error" in geocoded_info:
        return geocoded_info
    
    lat, lon, pincode = geocoded_info["latitude"], geocoded_info["longitude"], geocoded_info["pincode"]
    post_offices = fetch_post_offices_by_pincode(pincode)

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

# Main execution flow
if __name__ == "__main__":
    try:
        # Ensure a photo path is passed as an argument
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
        print("\nExtracted Address:", address)
        
        

        # Step 2: Use extracted address as input for geocoding and find nearest post office
        with open("credentials.json", "r") as file:
            credentials = json.load(file)
        
        api_key = credentials["google_api_key"]

        geocoded_info = geocode_address(api_key, address)
        if "error" in geocoded_info:
            print("\nGeocoding failed:", geocoded_info["error"])
        else:
            print("\nGeocoding Result:")
            print(f"Formatted Address: {geocoded_info['formattedAddress']}")
            print(f"Latitude: {geocoded_info['latitude']}")
            print(f"Longitude: {geocoded_info['longitude']}")
            print(f"Pincode: {geocoded_info['pincode']}")
            print(f"City: {geocoded_info['city']}")
            print(f"State: {geocoded_info['state']}")

            print("\nGoogle Maps Link for Geocoded Location:")
            print(create_google_maps_link(geocoded_info["latitude"], geocoded_info["longitude"]))

            nearest_post_office = find_nearest_post_office(api_key, address)
            if "error" in nearest_post_office:
                print("\nError:", nearest_post_office["error"])
            else:
                print("\nPost Office Details from Database:")
                print(f"Name: {nearest_post_office['name']}")
                print(f"Pincode: {nearest_post_office['pincode']}")
                print(f"Delivery: {nearest_post_office['delivery_type']}")
                print(f"State: {nearest_post_office['state']}")
                print(f"Latitude: {nearest_post_office['latitude']}")
                print(f"Longitude: {nearest_post_office['longitude']}")
                print(f"Office Type: {nearest_post_office['office_type']}")

    except HttpResponseError as error:
        print("Error:", error)
