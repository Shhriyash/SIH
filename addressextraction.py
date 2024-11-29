from azure.core.credentials import AzureKeyCredential
from azure.ai.formrecognizer import DocumentAnalysisClient, AnalysisFeature
import sys
from azure.core.exceptions import HttpResponseError
import os
import json
import re

address_info = {
    "address" : "",
    "word_confidence_score": {}
}


def format_bounding_region(bounding_regions):
    if not bounding_regions:
        return "N/A"
    return ", ".join(
        f"Page #{region.page_number}: {format_polygon(region.polygon)}"
        for region in bounding_regions
    )


def format_polygon(polygon):
    if not polygon:
        return "N/A"
    return ", ".join([f"[{p.x}, {p.y}]" for p in polygon])


def analyze_read():

    endpoint = os.environ["DI_ENDPOINT"]
    key = os.environ["DI_KEY"]

    document_analysis_client = DocumentAnalysisClient(
        endpoint=endpoint, credential=AzureKeyCredential(key)
    )

    path_to_document = "New folder\WhatsApp Image 2024-11-29 at 15.28.40_6f5d2511.jpg"

    with open(path_to_document, "rb") as f:
        poller = document_analysis_client.begin_analyze_document(
            "prebuilt-read", document=f, features=[AnalysisFeature.LANGUAGES]
        )
    result = poller.result()
    

    print("----Languages detected in the document----")
    for language in result.languages:
        print(
            f"Language code: '{language.locale}' with confidence {language.confidence}"
        )

    for page in result.pages:
        print(f"----Analyzing document from page #{page.page_number}----")
        print(
            f"Page has width: {page.width} and height: {page.height}, measured with unit: {page.unit}"
        )
        
        address = ""
        for line_idx, line in enumerate(page.lines):
            if address_info["address"]:
                address_info["address"] += " "
                address +=" "
            address_info["address"] += line.content
            address += line.content
            words = line.get_words()
            print(
                f"Line - {line_idx} has {len(words)} words and text '{line.content}"
            )


            for word in words:

                if word.content not in address_info["word_confidence_score"]:
                            address_info["word_confidence_score"][word.content] = word.confidence
                else:
                    address_info["word_confidence_score"][word.content] = min(
                        address_info["word_confidence_score"][word.content], word.confidence)
                print(
                    f"    Word '{word.content}' has a confidence of {word.confidence}"
                )

                #extracting pincode
                pincode = next(
                    (word for word in address_info["word_confidence_score"].keys() if re.fullmatch(r"\d{6}", word)),
                    None  
                )

    print("----------------------------------------")
    json_result = json.dumps(address_info, indent=4)

    print(json_result)
    print("pincode is :", pincode)
    print("address is :",address)

    # Set confidence threshold
    confidence_threshold = 0.5000
    filtered_words = {
    word: score
    for word, score in address_info["word_confidence_score"].items()
    if score <= confidence_threshold
                                        }
    address_pincode = {'address': address,
                       'pincode':pincode}  

    print("Filtered Words:", filtered_words)
    with open ('address_pincode' , 'w') as f:
        json.dump(address_pincode,f,indent=4)


if __name__ == "__main__":

    try:
        analyze_read()
    except HttpResponseError as error:
        print(
            "For more information about troubleshooting errors, see the following guide: "
            "https://aka.ms/azsdk/python/formrecognizer/troubleshooting"
        )

        if error.error is not None:
            if error.error.code == "InvalidImage":
                print(f"Received an invalid image error: {error.error}")
            if error.error.code == "InvalidRequest":
                print(f"Received an invalid request error: {error.error}")

            raise

        if "Invalid request".casefold() in error.message.casefold():
            print(f"Uh-oh! Seems there was an invalid request: {error}")

        raise