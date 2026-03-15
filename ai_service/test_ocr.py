import os
try:
    import httpx
except ImportError:
    print("Error: httpx not found in this environment. Please run 'pip install httpx'")
    exit(1)

url = "http://localhost:8000/api/ai/ocr/"
image_path = "../web/favicon.png"

if not os.path.exists(image_path):
    print(f"Error: image not found at {image_path}")
    exit(1)

files = {'file': ('favicon.png', open(image_path, 'rb'), 'image/png')}
data = {'patient_id': '1'}

print(f"Testing OCR endpoint at {url}...")
with httpx.Client() as client:
    try:
        response = client.post(url, files=files, data=data, timeout=30.0)
        print(f"Status Code: {response.status_code}")
        print(f"Response Body: {response.text}")
    except Exception as e:
        print(f"Error type: {type(e)}")
        print(f"Error message: {e}")
