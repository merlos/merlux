import json 
import csv

def convert_json_to_csv(json_file, csv_file):
    with open(json_file, 'r', encoding='utf-8') as file:
        data = json.load(file)
    
    with open(csv_file, 'w', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)
        writer.writerow(["mac_address", "name"])
        
        for entry in data.get("macFilterList", []):
            writer.writerow([entry.get("mac", ""), entry.get("hostname", "")])

if __name__ == "__main__":
    input_json = "../etc/macs.json"  # Change this to your JSON filename
    output_csv = "../etc/macs.csv"  # Change this to your desired CSV filename
    convert_json_to_csv(input_json, output_csv)
    print(f"CSV file '{output_csv}' created successfully.")
