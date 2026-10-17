# Copyright (c) 2026 Kevin Collins.
# SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
"""Compare the built PasJPEG fixture with Pillow's independent JPEG codec.

Usage: python3 VerifyInterop.py fixture-executable output-directory
Pillow is an optional verification dependency, not a PasJPEG dependency.
"""
import json
from pathlib import Path
import subprocess
import sys

from PIL import Image, ImageChops, ImageStat


fixture = Path(sys.argv[1]).resolve()
output = Path(sys.argv[2]).resolve()
output.mkdir(parents=True, exist_ok=True)
source = Image.new("RGB", (65, 49))
source.putdata([
    (x * 3, y * 5, (x + y) * 2)
    for y in range(source.height) for x in range(source.width)
])
source.save(output / "input.bmp")
results = []


def run(mode, input_name, output_name):
    completed = subprocess.run(
        [str(fixture), mode, str(output / input_name), str(output / output_name)],
        capture_output=True, text=True, timeout=30, check=True,
    )
    if completed.stderr:
        raise AssertionError(completed.stderr)


run("encode", "input.bmp", "pasjpeg.jpg")
with Image.open(output / "pasjpeg.jpg") as image:
    image.load()
    assert image.size == source.size
    difference = ImageStat.Stat(ImageChops.difference(image.convert("RGB"), source))
    assert max(difference.mean) < 4, difference.mean
    results.append({"case": "PasJPEG encode / Pillow decode", "mean_error": difference.mean})

for progressive in (False, True):
    name = "progressive" if progressive else "baseline"
    source.save(output / (name + ".jpg"), quality=95, progressive=progressive)
    run("decode", name + ".jpg", name + ".bmp")
    with Image.open(output / (name + ".jpg")) as reference:
        with Image.open(output / (name + ".bmp")) as actual:
            assert actual.size == reference.size
            difference = ImageStat.Stat(ImageChops.difference(
                reference.convert("RGB"), actual.convert("RGB")))
            assert max(difference.mean) < 1, difference.mean
            assert max(high for low, high in difference.extrema) <= 3, difference.extrema
            results.append({"case": "Pillow " + name + " / PasJPEG decode",
                            "mean_error": difference.mean, "extrema": difference.extrema})

source.convert("L").save(output / "grayscale.jpg", quality=95)
run("decode", "grayscale.jpg", "grayscale.bmp")
with Image.open(output / "grayscale.jpg") as reference:
    with Image.open(output / "grayscale.bmp") as actual:
        assert actual.size == reference.size
        difference = ImageStat.Stat(ImageChops.difference(reference, actual.convert("L")))
        assert difference.extrema[0][1] <= 1, difference.extrema
        results.append({"case": "Pillow grayscale / PasJPEG decode", "extrema": difference.extrema})

result_path = output / "results.json"
result_path.write_text(json.dumps(results, indent=2) + "\n")
print(json.dumps(results, indent=2))
