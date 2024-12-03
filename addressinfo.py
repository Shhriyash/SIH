from groq import Groq
import os

os.environ["Api"]="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"
apikey = os.environ["Api"]


#add your address

address="""Flat No. 405, Sai Kripa Apartments, Vijay Nagar, Indore, 452010
9876543210
Anjali Verma"""
client = Groq(api_key=apikey)
completion = client.chat.completions.create(
    model="llama-3.1-70b-versatile",
     messages=[{
            "role": "system",
            "content": """identify address , pincode , phone number and name if present .
             If the there is any hint whether the address is of receiver or sender print that .
             Remember do not print anything else other than the details i asked.Give response in json"""
        },
        {
            "role": "user",
            "content": address ,
        }],
    temperature=1,
    max_tokens=1024,
    top_p=1,
    stream=True,
    stop=None,
)

for chunk in completion:
    print(chunk.choices[0].delta.content or "", end="")



