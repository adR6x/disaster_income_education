import os
import googlemaps
import pandas as pd
from tqdm import tqdm

def get_geolocations(address, api_key):
    client = googlemaps.Client(key=api_key)
    results = client.geocode(address)
    geocodes = []
    if results:
        for res in results:
            loc = res['geometry']['location']
            geocodes.append((loc['lat'], loc['lng']))
    return geocodes

def main():
    API_KEY = os.environ.get("GOOGLE_MAPS_API_KEY")  # set via environment variable
    df = pd.read_csv("../1_data/2_clean/vdcs_list_hrvs.csv")
    output_rows = []
    max_results = 0

    for _, row in tqdm(df.iterrows(), total=len(df), desc="Processing addresses"):
        address = f"{row['district']} {row['vdc']}"
        geocodes = get_geolocations(address, API_KEY)
        max_results = max(max_results, len(geocodes))
        row_dict = {'district': row['district'], 'vdc': row['vdc']}
        if geocodes:
            row_dict['lat'] = geocodes[0][0]
            row_dict['long'] = geocodes[0][1]
            for i in range(1, len(geocodes)):
                row_dict[f'lat{i+1}'] = geocodes[i][0]
                row_dict[f'long{i+1}'] = geocodes[i][1]
        output_rows.append(row_dict)

    columns = ['district', 'vdc']
    if max_results >= 1:
        columns += ['lat', 'long']
    for i in range(2, max_results+1):
        columns += [f'lat{i}', f'long{i}']

    output_df = pd.DataFrame(output_rows).reindex(columns=columns)
    output_df.to_csv("../1_data/2_clean/vdcs_geo_list_hrvs.csv", index=False)

if __name__ == '__main__':
    main()
