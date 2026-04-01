import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
import os
import webbrowser

# Create output directory
output_dir = "plotly_outputs"
os.makedirs(output_dir, exist_ok=True)

# Load datasets
vdc_hrvs_eq_intense = pd.read_csv("../1_data/2_clean/vdc_hrvs_eq_intense.csv")
eq_df = pd.read_csv("../1_data/2_clean/earthquakes_2014_18_clean.csv")

# Sort and create lag variables
vdc_hrvs_eq_intense = vdc_hrvs_eq_intense.sort_values(by=['district', 'vdc', 'survey_year'])

# rename column survey_year to time
vdc_hrvs_eq_intense.rename(columns={"survey_year": "time"}, inplace=True)

for var in [1, 2]:
    vdc_hrvs_eq_intense[f"I_{var}_t"] = vdc_hrvs_eq_intense.groupby(['vdc', 'district'])[f'Intensity_{var}'].shift(1)
    vdc_hrvs_eq_intense[f"diff_I_{var}_t"] = vdc_hrvs_eq_intense[f'Intensity_{var}'] - vdc_hrvs_eq_intense[f"I_{var}_t"]

ordered_cols = [
    'vdc', 'district', 'Latitude', 'Longitude',
    'time', 
    'Intensity_1', 'I_1_t', 'diff_I_1_t',
    'Intensity_2', 'I_2_t', 'diff_I_2_t'
]
vdc_hrvs_eq_intense = vdc_hrvs_eq_intense[ordered_cols]

# Clean eq_df
eq_df["datetime"] = pd.to_datetime(eq_df["datetime"], errors="coerce")
eq_df = eq_df.drop_duplicates()
eq_df["time"] = pd.cut(eq_df["datetime"], 
                       bins=[pd.Timestamp("2014-06-30"),
                             pd.Timestamp("2015-06-01"), 
                             pd.Timestamp("2016-06-01"), 
                             pd.Timestamp("2017-06-01"), 
                             pd.Timestamp("2018-06-02")], 
                       labels=["2015","2016", "2017", "2018"])
assert eq_df['datetime'].isna().sum() == 0
assert eq_df['time'].isna().sum() == 0

keyboard_script = """
<script>
document.addEventListener('DOMContentLoaded', () => {
  const plots = document.querySelectorAll('div.js-plotly-plot');
  plots.forEach((plot) => {
    let activeIndex = 0;
    const steps = plot.layout.sliders?.[0]?.steps || [];
    function triggerStep(index) {
      const step = steps[index];
      Plotly.restyle(plot, step.args[0]);
      Plotly.relayout(plot, step.args[1]);
      Plotly.relayout(plot, { 'sliders[0].active': index });
    }
    document.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowRight' && activeIndex < steps.length - 1) {
        activeIndex++;
        triggerStep(activeIndex);
      } else if (e.key === 'ArrowLeft' && activeIndex > 0) {
        activeIndex--;
        triggerStep(activeIndex);
      }
    });
  });
});
</script>
"""

# First slider-based map: diff_I_1_t
fig_map = go.Figure()
for year in [2016, 2017, 2018]:
    subset = vdc_hrvs_eq_intense[vdc_hrvs_eq_intense["time"] == year].copy()
    fig_map.add_trace(go.Scattermapbox(
        lat=subset["Latitude"],
        lon=subset["Longitude"],
        mode='markers',
        marker=go.scattermapbox.Marker(
            size=8,
            color=subset["diff_I_1_t"],
            colorscale="Blues_r",
            showscale=True,
            colorbar=dict(title="diff_I_1_t")
        ),
        text=subset["vdc"],
        hoverinfo="text",
        name=str(year),
        visible=(year == 2016)
    ))

fig_map.update_layout(
    mapbox_style="open-street-map",
    mapbox_zoom=6,
    mapbox_center={"lat": 28.3225638, "lon": 84.0741416},
    margin={"r":40,"t":40,"l":40,"b":40},
    title="Difference in Intensity from previous year, t=2016",
    sliders=[{
        "steps": [
            {
                "method": "update",
                "label": str(year),
                "args": [
                    {"visible": [y == year for y in [2016, 2017, 2018]]},
                    {"title.text": f"Difference in Intensity from previous year, t={year}"}
                ]
            } for year in [2016, 2017, 2018]
        ],
        "active": 0,
        "x": 0.1,
        "y": -0.1,
        "len": 0.9,
        "transition": {"duration": 300, "easing": "cubic-in-out"},
        "currentvalue": {"prefix": "Year: "},
        "pad": {"t": 30}
    }]
)

map_file_path = os.path.abspath(f"{output_dir}/diff_I_1_t_map_slider.html")
fig_map.write_html(map_file_path, include_plotlyjs='cdn', full_html=True)
with open(map_file_path, "a") as f:
    f.write(keyboard_script)
webbrowser.open(f"file://{map_file_path}")

# Second slider-based map: Intensity_1 and Earthquakes
fig_combo = go.Figure()
for year in [2015, 2016, 2017, 2018]:
    vdc_year = vdc_hrvs_eq_intense[vdc_hrvs_eq_intense["time"] == year]
    eq_year = eq_df[eq_df["time"] == str(year)]

    fig_combo.add_trace(go.Scattermapbox(
        lat=vdc_year["Latitude"],
        lon=vdc_year["Longitude"],
        mode='markers',
        marker=go.scattermapbox.Marker(
            size=6,
            color=vdc_year["Intensity_1"],
            colorscale='Plasma',
            showscale=True
        ),
        text=vdc_year["vdc"],
        hoverinfo="text",
        name=f"VDC {year}",
        visible=(year == 2015)
    ))

    fig_combo.add_trace(go.Scattermapbox(
        lat=eq_year["Latitude"],
        lon=eq_year["Longitude"],
        mode='markers',
        marker=go.scattermapbox.Marker(
            size=eq_year["Magnitude"] * 2,
            color='black',
            opacity=0.7
        ),
        text=eq_year["Magnitude"].apply(lambda x: f"M {x}"),
        hoverinfo="text",
        name=f"EQ {year}",
        visible=(year == 2015)
    ))

fig_combo.update_layout(
    mapbox_style="open-street-map",
    mapbox_zoom=6,
    mapbox_center={"lat": 28.3225638, "lon": 84.0741416},
    margin={"r":40,"t":40,"l":40,"b":40},
    title="Intensity_1 and Earthquakes in 2015",
    sliders=[{
        "steps": [
            {
                "method": "update",
                "label": str(year),
                "args": [
                    {"visible": [i // 2 == j for i in range(8)]},
                    {"title.text": f"Intensity_1 and Earthquakes in {year}"}
                ]
            } for j, year in enumerate([2015, 2016, 2017, 2018])
        ],
        "active": 0,
        "x": 0.1,
        "y": -0.1,
        "len": 0.9,
        "transition": {"duration": 300, "easing": "cubic-in-out"},
        "currentvalue": {"prefix": "Year: "},
        "pad": {"t": 30}
    }]
)

combo_file_path = os.path.abspath(f"{output_dir}/eq_intensity_epicenter_slider.html")
fig_combo.write_html(combo_file_path, include_plotlyjs='cdn', full_html=True)
with open(combo_file_path, "a") as f:
    f.write(keyboard_script)
webbrowser.open(f"file://{combo_file_path}")