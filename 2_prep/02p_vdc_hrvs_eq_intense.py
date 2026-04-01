import pandas as pd
import numpy as np
from geopy.distance import geodesic as gd
import plotly.express as px
import plotly.graph_objects as go

# Load VDC data
vdc_df = pd.read_csv("../1_data/2_clean/vdcs_geo_list_hrvs_mnl.csv")
vdc_df = vdc_df.dropna(subset=["lat", "long"])

# Rename columns for clarity
vdc_df.rename(columns={"lat": "Latitude", "long": "Longitude"}, inplace=True)

eq_df = pd.read_csv("../1_data/2_clean/earthquakes_2014_18_clean.csv")
eq_df = eq_df[["datetime", "Latitude", "Longitude", "Magnitude"]]
# rename datetime to Date AD
eq_df.rename(columns={"datetime": "Date AD"}, inplace=True)

# drop duplicates in eq_df, keep the first occurrence
eq_df = eq_df.drop_duplicates()

eq_df["Date AD"] = pd.to_datetime(eq_df["Date AD"], errors="coerce")
assert eq_df['Date AD'].isna().sum() == 0, "Missing values found in 'datetime'"

eq_df = eq_df.dropna(subset=["Date AD"]).sort_values("Date AD")

# filter eq_df on date after June 2015
eq_df = eq_df[eq_df["Date AD"] >= pd.to_datetime("2014-06-01")]
# filter eq_df on date before June 2018
eq_df = eq_df[eq_df["Date AD"] < pd.to_datetime("2018-06-01")]

# Calculate distance between VDCs and earthquakes
def calculate_distance(row):
    vdc_coords = (row["Latitude"], row["Longitude"])
    eq_coords = (row["Latitude_eq"], row["Longitude_eq"])
    return gd(vdc_coords, eq_coords).km

# Create a new DataFrame to store distances
distances = []
for _, vdc_row in vdc_df.iterrows():
    for _, eq_row in eq_df.iterrows():
        distance = calculate_distance({
            "Latitude": vdc_row["Latitude"],
            "Longitude": vdc_row["Longitude"],
            "Latitude_eq": eq_row["Latitude"],
            "Longitude_eq": eq_row["Longitude"]
        })
        distances.append({
            "vdc": vdc_row["vdc"],
            "district": vdc_row["district"],
            "Date": eq_row["Date AD"],
            "Distance (km)": distance,
            "Magnitude": eq_row["Magnitude"],
            "Latitude": vdc_row["Latitude"],
            "Longitude": vdc_row["Longitude"]
        })
        
distances_df = pd.DataFrame(distances)

# Calculate magnitude/distance^2
distances_df["Intensity_1"] = 1.48 +1.16 * distances_df["Magnitude"] - 1.35* np.log10(distances_df["Distance (km)"]+ np.exp(0.48*distances_df["Magnitude"]))
distances_df["Intensity_2"] = 1.889 +0.3996 * distances_df["Magnitude"] - 0.95736* np.log10(distances_df["Distance (km)"]+ np.exp(0.4114*distances_df["Magnitude"]))


# Create time bins
distances_df["time"] = pd.cut(distances_df["Date"], 
                                    bins=[pd.Timestamp("2014-06-30"),
                                          pd.Timestamp("2015-06-01"), 
                                          pd.Timestamp("2016-06-01"), 
                                          pd.Timestamp("2017-06-01"), 
                                          pd.Timestamp("2018-06-02")], 
                                    labels=["2015","2016", "2017", "2018"])

assert distances_df['time'].isna().sum() == 0, "Missing values found in 'time'"

# convert labesl on time to int
distances_df["time"] = distances_df["time"].astype(int)

keep_columns = ["vdc", "district", "time", "Latitude", "Longitude", "Intensity_1", "Intensity_2"]
grouped_df = distances_df[keep_columns]

# sum Intensity over VDC, District, and time
grouped_df = grouped_df.groupby(['vdc', 'district', 'time'], as_index=False, observed=True).agg({
    'Intensity_1': 'sum',
    'Intensity_2': 'sum',
    "Latitude": 'first',
    "Longitude" : 'first'
})

# remane time to survey_year
grouped_df.rename(columns={"time": "survey_year"}, inplace=True)

# Save the result to a CSV file
grouped_df.to_csv("../1_data/2_clean/vdc_hrvs_eq_intense.csv", index=False)

# Save the result to a dta file
grouped_df.to_stata("../1_data/2_clean/vdc_hrvs_eq_intense.dta", write_index=False)