"""
Applet: Awair
Summary: Get Awair air quality data.
Description: Get Awair air quality data from local Awair device.
Author: tabrindle
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")


def get_schema():
    return schema.Schema(
        version="1",
        fields=[
            schema.Text(
                id="ip_address",
                name="IP Address",
                desc="The IP address of your Awair device.",
                icon="key",
            ),
            schema.Toggle(
                id="celsius",
                name="Celsius",
                desc="Use celcius instead of fahrenheit.",
                icon="temperature-low",
                default=False,
            ),
        ],
    )


green = "#41b942"
yellow = "#fcd026"
yellow_orange = "#fba905"
orange = "f78703"
red = "#e8333a"

awair_color_map = [
    {"range": 80, "color": green},
    {"range": 60, "color": yellow_orange},
    {"range": 0, "color": red},
]

rh_color_map = [
    {"range": 80, "color": red},
    {"range": 65, "color": orange},
    {"range": 60, "color": yellow_orange},
    {"range": 50, "color": yellow},
    {"range": 40, "color": green},
    {"range": 35, "color": yellow},
    {"range": 20, "color": yellow_orange},
    {"range": 15, "color": orange},
    {"range": 0, "color": red},
]

co2_color_map = [
    {"range": 2500, "color": red},
    {"range": 1500, "color": orange},
    {"range": 1000, "color": yellow_orange},
    {"range": 600, "color": yellow},
    {"range": 400, "color": green},
]

temp_color_map = [
    {"range": 33.333, "color": red},  # 92F
    {"range": 31.667, "color": orange},  # 89F
    {"range": 26.111, "color": yellow_orange},  # 79F
    {"range": 25, "color": yellow},  # 77F
    {"range": 17.778, "color": green},  # 64F
    {"range": 16.667, "color": yellow},  # 62F
    {"range": 10.556, "color": yellow_orange},  # 51F
    {"range": 8.889, "color": orange},  # 48F
    {"range": 0, "color": red},
]

pm_color_map = [
    {"range": 75, "color": red},
    {"range": 55, "color": orange},
    {"range": 35, "color": yellow_orange},
    {"range": 15, "color": yellow},
    {"range": 0, "color": green},
]


def get_color(score, color_map):
    default = "#fff"

    for item in color_map:
        if score >= item["range"]:
            return item["color"]

    return default


def main(config):
    celsius = config.bool("celsius", False)
    ip_address = config.str("ip_address", "")

    if not ip_address:
        return render.Root(
          child = render.Text(
              content="Bad IP Address",
              font="tb-8",
              color="#f00",
          )
        )

    response = http.get("http://{}/air-data/latest".format(ip_address))
    body = response.body()
    data = json.decode(body)

    if celsius:
        temperature = data["temp"]
    else:
        temperature = data["temp"] * 9 / 5 + 32 

    return render.Root(
        child=render.Box(
            padding=0,
            child=render.Row(
                children=[
                    render.Box(
                        height=32,
                        width=38,
                        child=render.Column(
                            children=[
                                render.Text(
                                    content="Temp "
                                    + str(temperature)[0:2],
                                    font="tb-8",
                                    color=get_color(data["temp"], temp_color_map),
                                ),
                                render.Text(
                                    content="RH    " + str(data["humid"])[0:2],
                                    font="tb-8",
                                    color=get_color(data["humid"], rh_color_map),
                                ),
                                render.Text(
                                    content="CO2 " + str(data["co2"]),
                                    font="tb-8",
                                    color=get_color(400, co2_color_map),
                                ),
                                render.Text(
                                    content="PM25  " + str(data["pm25"]),
                                    font="tb-8",
                                    color=get_color(data["pm25"], pm_color_map),
                                ),
                            ]
                        ),
                    ),
                    render.Box(
                        height=32,
                        width=28,
                        child=render.Column(
                            main_align="start",
                            children=[
                                render.Stack(
                                    children=[
                                        render.Circle(
                                            diameter=18,
                                            color=get_color(
                                                data["score"], awair_color_map
                                            ),
                                        ),
                                        render.Box(
                                            height=18,
                                            width=18,
                                            child=render.Text(
                                                content=str(data["score"]),
                                                font="Dina_r400-6",
                                                color="#fff",
                                            ),
                                        ),
                                    ]
                                )
                            ],
                        ),
                    ),
                ]
            ),
        )
    )
