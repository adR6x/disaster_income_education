import geopandas as gpd
import matplotlib.pyplot as plt
import contextily as ctx
import pandas as pd
from shapely.geometry import box

# Load and prepare data
vdc_hrvs_eq_intense = pd.read_csv("../1_data/2_clean/vdc_hrvs_eq_intense.csv")
eq_df = pd.read_csv("../1_data/2_clean/earthquakes_2014_18_clean.csv")
eq_df["datetime"] = pd.to_datetime(eq_df["datetime"], errors="coerce")
eq_df = eq_df.drop_duplicates()

# Clean VDC data
vdc_filtered = vdc_hrvs_eq_intense[vdc_hrvs_eq_intense["survey_year"].isin([2017, 2018])]
# Group and sum intensities
vdc_grouped = vdc_filtered.groupby(
    ["vdc", "district", "Latitude", "Longitude"], as_index=False
)[["Intensity_1", "Intensity_2"]].sum()

gdf_vdc = gpd.GeoDataFrame(
    vdc_grouped,
    geometry=gpd.points_from_xy(vdc_grouped.Longitude, vdc_grouped.Latitude),
    crs="EPSG:4326"
).to_crs(epsg=3857)

eq_df["time"] = pd.cut(
    eq_df["datetime"],
    bins=[
        pd.Timestamp("2014-06-30"),
        pd.Timestamp("2015-06-01"),
        pd.Timestamp("2016-06-01"),
        pd.Timestamp("2017-06-01"),
        pd.Timestamp("2018-06-02")
    ],
    labels=["2015", "2016", "2017", "2018"]
)

eq_df = eq_df[(eq_df["Latitude"].between(16, 31)) & (eq_df["Longitude"].between(80, 89))]

# Convert to GeoDataFrame
gdf = gpd.GeoDataFrame(
    eq_df,
    geometry=gpd.points_from_xy(eq_df.Longitude, eq_df.Latitude),
    crs="EPSG:4326"
)

# Convert projection for contextily basemap compatibility
gdf = gdf.to_crs(epsg=3857)

# Separate filtered GeoDataFrames
gdf_all = gdf.copy()
gdf_1718 = gdf[gdf["time"].isin(["2017", "2018"])]

fig, ax = plt.subplots(figsize=(10, 10))

gdf_all.plot(
    ax=ax,
    column='time',
    cmap='bwr',
    alpha=0.7,
    markersize=gdf_all['Magnitude']**3,
    legend=True,
    legend_kwds={'title': 'Year'},
    marker='h',
    edgecolor='face'
)

# Set bounds
minx, miny, maxx, maxy = 79.5, 26, 88.5, 31
bbox = gpd.GeoDataFrame(geometry=[box(minx, miny, maxx, maxy)], crs="EPSG:4326").to_crs(epsg=3857).total_bounds
ax.set_xlim(bbox[0], bbox[2])
ax.set_ylim(bbox[1], bbox[3])

# Add basemap
ctx.add_basemap(ax, source=ctx.providers.USGS.USTopo)

# ax.set_title('Earthquakes in Nepal (June 2014– June 2018)', fontsize=15)
ax.set_axis_off()

plt.tight_layout()
plt.savefig("../5_fig/fig_earthquakes_15_18.pdf", bbox_inches='tight')
plt.show()
plt.close()

# For 2017-2018 earthquakes
fig, ax = plt.subplots(figsize=(10, 10))

gdf_1718.plot(
    ax=ax,
    column='time',
    cmap='bwr',
    alpha=0.7,
    markersize=gdf_1718['Magnitude']**3,
    legend=True,
    legend_kwds={'title': 'Year'},
    marker='h',
    edgecolor='red'
)

ax.set_xlim(bbox[0], bbox[2])
ax.set_ylim(bbox[1], bbox[3])
ctx.add_basemap(ax, source=ctx.providers.USGS.USTopo)

# ax.set_title('Earthquakes in Nepal (June 2016– June 2018)', fontsize=15)
ax.set_axis_off()

plt.tight_layout()
plt.savefig("../5_fig/fig_earthquakes_17_18.pdf", bbox_inches='tight')
plt.show()
plt.close()


# For 2017-2018 and survey VDCs earthquakes
fig, ax = plt.subplots(figsize=(10, 10))

gdf_1718.plot(
    ax=ax,
    column='time',
    cmap='bwr',
    alpha=0.7,
    markersize=gdf_1718['Magnitude']**3,
    legend=True,
    legend_kwds={'title': 'Year'},
    marker='h',
    edgecolor='red'
)

gdf_vdc.plot(
    ax=ax,
    column="Intensity_1",
    cmap="seismic",
    alpha=1,
    markersize=10,
    edgecolor="black",
    legend_kwds={"label": "Summed Intensity_1 (2017–2018)"}
)

ax.set_xlim(bbox[0], bbox[2])
ax.set_ylim(bbox[1], bbox[3])
ctx.add_basemap(ax, source=ctx.providers.USGS.USTopo)

# ax.set_title('HRVS and Earthquakes in Nepal (June 2016– June 2018)', fontsize=15)
ax.set_axis_off()

plt.tight_layout()
plt.savefig("../5_fig/fig_earthquakes_hrvs_17_18.pdf", bbox_inches='tight')
plt.show()
plt.close()

