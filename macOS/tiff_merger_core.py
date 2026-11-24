#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Shared core logic for TIFF Channel Merger (macOS).

Used by the CLI (tiff_channel_merger_cli.py) and the Tkinter GUI
(tiff_channel_merger_gui.py):
- the GUI uses the batch helpers (BatchJob, batch config load/save, batch
  report) and, when pyvips is available (always in the .dmg app),
  merge_channels_pyvips() with the embedded libvips. Without pyvips it falls
  back to its own `vips` command pipeline. It also writes an OME-XML sidecar.
- the CLI uses merge_channels() / process_merge_job() with the `vips` command.

merge_channels() mirrors the Windows version (windows/TIFF-Channel-Merger.ps1):
- bandjoin merges directly into a .v (VIPS native) intermediate file to avoid
  VIPS' 50MB cumulative memory limit on TIFF reload, then tiffsave produces the
  final pyramidal TIFF from the .v file.
- Pyramidal TIFFs are always LZW-compressed, tiled 256x256, BigTIFF.
- No .ome.xml sidecar is generated (disabled upstream: Python-based OME-XML
  injection corrupts large pyramidal TIFFs, so Windows dropped the sidecar too).
  Only a channel names text file and a QuPath Groovy import script are produced.

Copyright (c) 2024 Loic Talignani & Celine Talignani
This work is licensed under the Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 International License.
"""

import json
import os
import shutil
import subprocess
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import List, Optional

BATCH_CONFIG_VERSION = "1.0"

VIPS_CANDIDATE_PATHS = [
    "/opt/homebrew/bin/vips",  # Apple Silicon Homebrew
    "/usr/local/bin/vips",     # Intel Homebrew
    "/opt/local/bin/vips",     # MacPorts
]


class MergeError(Exception):
    """Raised when a VIPS merge step fails."""


def find_vips() -> Optional[str]:
    """Locate the vips executable, checking common Homebrew/MacPorts paths first, then PATH."""
    for path in VIPS_CANDIDATE_PATHS:
        if os.path.exists(path):
            try:
                subprocess.run([path, "--version"], capture_output=True, check=True)
                return path
            except (subprocess.CalledProcessError, OSError):
                continue
    return shutil.which("vips")


BREW_CANDIDATE_PATHS = [
    "/opt/homebrew/bin/brew",  # Apple Silicon
    "/usr/local/bin/brew",     # Intel
]


def find_brew() -> Optional[str]:
    """Locate Homebrew. Checks the standard install paths first because an app
    launched from the Finder does not have Homebrew's bin folder in its PATH."""
    for path in BREW_CANDIDATE_PATHS:
        if os.access(path, os.X_OK):
            return path
    return shutil.which("brew")


def homebrew_available() -> bool:
    """Check whether Homebrew itself is installed."""
    return find_brew() is not None


def install_vips_via_brew() -> subprocess.CompletedProcess:
    """Run `brew install vips`. Caller must check homebrew_available() first."""
    brew_path = find_brew()
    env = os.environ.copy()
    # Finder-launched apps get a minimal PATH; brew needs its own bin folder
    env["PATH"] = f"{os.path.dirname(brew_path)}:{env.get('PATH', '/usr/bin:/bin:/usr/sbin:/sbin')}"
    return subprocess.run([brew_path, "install", "vips"], capture_output=True, text=True,
                          check=False, env=env)


def _vips_env():
    env = os.environ.copy()
    env["VIPS_DISC_THRESHOLD"] = "100m"
    env["VIPS_CONCURRENCY"] = "1"
    env["VIPS_NOVECTOR"] = "1"
    env["LIBTIFF_WARNINGS"] = "no"
    return env


def merge_channels(vips_path: str, files: List[str], output_tif: str, pyramid: bool = True):
    """Merge single-channel TIFFs into output_tif.

    Uses a .v (VIPS native format) intermediate file for the bandjoin step so the
    50MB cumulative memory limit VIPS applies to TIFF loading never comes into play,
    then converts that .v file to the final pyramidal TIFF.

    Returns (bandjoin_stdout, tiffsave_stdout). Raises MergeError on failure.
    """
    output_path = Path(output_tif)
    temp_v = output_path.parent / f"{output_path.stem}_temp.v"

    env = _vips_env()
    file_list = " ".join(f'"{f}"' for f in files)

    bandjoin_cmd = f'"{vips_path}" bandjoin "{file_list}" "{temp_v}"'
    bandjoin_result = subprocess.run(bandjoin_cmd, shell=True, capture_output=True, text=True, env=env)
    if bandjoin_result.returncode != 0:
        raise MergeError(f"bandjoin failed: {bandjoin_result.stderr.strip()}")

    save_options = ["--compression=lzw", "--bigtiff"]
    if pyramid:
        save_options += ["--tile", "--tile-width=256", "--tile-height=256", "--pyramid"]

    tiffsave_cmd = f'"{vips_path}" tiffsave "{temp_v}" "{output_path}" ' + " ".join(save_options)
    tiffsave_result = subprocess.run(tiffsave_cmd, shell=True, capture_output=True, text=True, env=env)

    if temp_v.exists():
        temp_v.unlink()

    if tiffsave_result.returncode != 0:
        raise MergeError(f"tiffsave failed: {tiffsave_result.stderr.strip()}")

    return bandjoin_result.stdout, tiffsave_result.stdout


# ---------------------------------------------------------------------------
# In-process merge with pyvips (libvips embedded in the .dmg app)
# ---------------------------------------------------------------------------

_pyvips = None


def _load_pyvips():
    """Import pyvips once. libvips reads its settings from the environment when
    it starts, so they must be set before the first import."""
    global _pyvips
    if _pyvips is None:
        os.environ.setdefault("VIPS_DISC_THRESHOLD", "100m")  # decode big images to disk, not RAM
        os.environ.setdefault("VIPS_CONCURRENCY", "2")
        os.environ.setdefault("LIBTIFF_WARNINGS", "no")
        import pyvips
        pyvips.cache_set_max(0)  # no operation cache: batch jobs must not pile up memory
        _pyvips = pyvips
    return _pyvips


def pyvips_available() -> bool:
    """True if pyvips and a working libvips can be loaded (always true in the .dmg app)."""
    try:
        _load_pyvips()
        return True
    except Exception:  # ImportError, or OSError/cffi error when libvips is missing
        return False


def pyvips_description() -> str:
    pyvips = _load_pyvips()
    return f"pyvips {pyvips.__version__} / libvips {pyvips.version(0)}.{pyvips.version(1)}.{pyvips.version(2)}"


def merge_channels_pyvips(files: List[str], output_tif: str, pyramid: bool = True) -> str:
    """Merge single-channel TIFFs into output_tif with the embedded libvips.

    Same output as the vips command line (LZW, BigTIFF, 256x256 tiles and a
    pyramid when requested). Inputs are read sequentially and streamed straight
    into tiffsave, so no intermediate file is needed and memory stays bounded.
    A partial output file is removed on failure. Returns a short log text;
    raises MergeError on failure.
    """
    pyvips = _load_pyvips()
    try:
        images = [pyvips.Image.new_from_file(f, access="sequential", unlimited=True) for f in files]
        merged = images[0].bandjoin(images[1:])
        options = {"compression": "lzw", "bigtiff": True}
        if pyramid:
            options.update(tile=True, tile_width=256, tile_height=256, pyramid=True)
        merged.tiffsave(output_tif, **options)
    except pyvips.Error as e:
        if os.path.exists(output_tif):
            os.remove(output_tif)
        raise MergeError(f"libvips: {str(e).strip()}") from e

    lines = [pyvips_description(), f"Output: {output_tif}",
             f"Size: {merged.width} x {merged.height}, {merged.bands} bands, {merged.format}",
             f"tiffsave options: {options}"]
    lines += [f"Input {i + 1}: {img.width} x {img.height}, {img.bands} band(s), {img.format} - {f}"
              for i, (f, img) in enumerate(zip(files, images))]
    return "\n".join(lines) + "\n"


def self_test() -> int:
    """Check that the embedded libvips can merge and write a pyramidal TIFF.
    Used by build_dmg.sh on the built app (`TIFF Channel Merger --self-test`)."""
    import tempfile
    try:
        pyvips = _load_pyvips()
        with tempfile.TemporaryDirectory() as tmp:
            inputs = []
            for i in range(3):
                path = os.path.join(tmp, f"ch{i}.tif")
                (pyvips.Image.black(600, 400) + 40 * (i + 1)).cast("uchar").tiffsave(path)
                inputs.append(path)
            out = os.path.join(tmp, "merged.tif")
            merge_channels_pyvips(inputs, out, pyramid=True)
            check = pyvips.Image.new_from_file(out)
            ok = check.bands == 3 and check.get("n-pages") > 1
            print(f"{pyvips_description()} - merged {check.width}x{check.height}, "
                  f"{check.bands} bands, {check.get('n-pages')} pyramid levels")
        print("SELF-TEST OK" if ok else "SELF-TEST FAILED: unexpected output")
        return 0 if ok else 1
    except Exception as e:
        print(f"SELF-TEST FAILED: {e}")
        return 1


def default_channel_names(files: List[str], channel_names: Optional[List[str]]) -> List[str]:
    """Fill in blank/missing channel names with 'Channel_N' defaults."""
    names = list(channel_names or [])
    names += [""] * (len(files) - len(names))
    return [n.strip() if n and n.strip() else f"Channel_{i + 1}" for i, n in enumerate(names)]


def write_channels_txt(output_base: str, channel_names: List[str]) -> str:
    """Write one channel name per line (LF endings), matching the format the Groovy script expects."""
    channels_file = f"{output_base}_channels.txt"
    Path(channels_file).write_text("\n".join(channel_names), encoding="utf-8", newline="\n")
    return channels_file


def write_qupath_groovy(output_base: str, channels_txt_path: str) -> str:
    """Write the QuPath Groovy import script.

    Content matches the current Windows script exactly: it reads channel names from
    the sidecar text file and re-applies them to the already-open image's existing
    channels (preserving their colors), rather than sidecar OME-XML (disabled - see
    module docstring).
    """
    channels_txt_posix = Path(channels_txt_path).as_posix()
    output_name = Path(output_base).name
    generated_on = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    groovy_script = f"""// QuPath script to import channel names from text file
// Auto-generated for: {output_name}.tif
// Generated on: {generated_on}

import qupath.lib.images.servers.ImageChannel
import qupath.lib.images.servers.ImageServerMetadata
import java.nio.file.Paths
import java.nio.file.Files

// Path to the channel names file (same directory as TIFF)
def channelFile = Paths.get('{channels_txt_posix}')

if (!Files.exists(channelFile)) {{
    println "ERROR: Channel names file not found:"
    println channelFile.toString()
    return
}}

// Read channel names from file
def channelNames = Files.readAllLines(channelFile)
println "Found " + channelNames.size() + " channel names:"
channelNames.eachWithIndex {{ name, idx ->
    println "  Channel " + idx + ": " + name
}}

// Get current image data
def imageData = getCurrentImageData()
if (imageData == null) {{
    println "ERROR: No image is currently open"
    return
}}

// Get the server and current channels
def server = imageData.getServer()
def channels = server.getMetadata().getChannels()

if (channels.size() != channelNames.size()) {{
    println "WARNING: Number of channels in image (" + channels.size() + ") doesn't match number of names (" + channelNames.size() + ")"
}}

// Create new channels with custom names
def newChannels = []
for (int i = 0; i < channels.size(); i++) {{
    def name = i < channelNames.size() ? channelNames[i] : "Channel_" + i
    def color = channels[i].getColor()
    newChannels.add(ImageChannel.getInstance(name, color))
}}

// Update the image metadata using Builder constructor
def originalMetadata = server.getMetadata()
def newMetadata = new ImageServerMetadata.Builder(originalMetadata)
    .channels(newChannels)
    .build()

imageData.updateServerMetadata(newMetadata)

println ""
println "✅ Channel names updated successfully!"
println "The channel names should now appear in the Brightness/Contrast panel."

// Refresh the display
fireHierarchyUpdate()
"""

    script_path = Path(output_base).parent / f"QuPath_Import_{output_name}.groovy"
    script_path.write_text(groovy_script, encoding="utf-8", newline="\n")
    return str(script_path)


def process_merge_job(vips_path: str, files: List[str], channel_names: Optional[List[str]],
                       output_name: str, output_dir: str, pyramid: bool = True) -> dict:
    """Run one full merge job: VIPS merge + (if any channel name given) channels.txt + Groovy script.

    Returns a dict with the paths of every file created.
    """
    if len(files) < 2:
        raise ValueError("At least 2 files are required to merge channels.")

    output_base = str(Path(output_dir) / output_name)
    final_tif = f"{output_base}.tif"

    merge_channels(vips_path, files, final_tif, pyramid=pyramid)

    created = {"tif": final_tif, "channels_txt": None, "groovy": None}

    resolved_names = default_channel_names(files, channel_names)
    has_custom_names = bool(channel_names) and any(n and n.strip() for n in channel_names)
    if has_custom_names:
        channels_txt = write_channels_txt(output_base, resolved_names)
        groovy = write_qupath_groovy(output_base, channels_txt)
        created["channels_txt"] = channels_txt
        created["groovy"] = groovy

    return created


@dataclass
class BatchJob:
    job_name: str
    selected_files: List[str]
    channel_names: List[str] = field(default_factory=list)
    output_name: str = ""
    output_path: str = ""
    pyramid: bool = True  # Not in the Windows schema; Windows ignores the extra key and always builds pyramids
    status: str = "Pending"  # Pending, Running, Completed, Error
    error_message: str = ""
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None

    def duration_seconds(self) -> float:
        if self.start_time and self.end_time:
            return (self.end_time - self.start_time).total_seconds()
        return 0.0

    def to_dict(self) -> dict:
        return {
            "jobName": self.job_name,
            "selectedFiles": self.selected_files,
            "channelNames": self.channel_names,
            "outputName": self.output_name,
            "outputPath": self.output_path,
            "pyramid": self.pyramid,
            "status": self.status,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "BatchJob":
        return cls(
            job_name=data.get("jobName", ""),
            selected_files=list(data.get("selectedFiles") or []),
            channel_names=list(data.get("channelNames") or []),
            output_name=data.get("outputName", ""),
            output_path=data.get("outputPath", ""),
            pyramid=bool(data.get("pyramid", True)),
            status="Pending",  # Reset status when loading, matching Windows Load-BatchConfig
        )


def load_batch_config(path: str) -> List[BatchJob]:
    """Load a batch_jobs.json file. Compatible with the schema written by the Windows GUI
    (Save-BatchConfig / Load-BatchConfig in windows/TIFF-Channel-Merger.ps1)."""
    with open(path, "r", encoding="utf-8") as f:
        config = json.load(f)
    return [BatchJob.from_dict(job) for job in config.get("jobs", [])]


def save_batch_config(path: str, jobs: List[BatchJob]) -> None:
    """Save jobs using the same JSON schema as the Windows GUI, so files are interchangeable."""
    config = {
        "batchVersion": BATCH_CONFIG_VERSION,
        "created": datetime.now().astimezone().isoformat(),
        "jobs": [job.to_dict() for job in jobs],
    }
    with open(path, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2, ensure_ascii=False)


def generate_batch_report(jobs: List[BatchJob], output_dir: str, batch_start_time: datetime) -> str:
    """Write batch_report.txt summarizing completed/errored/pending jobs, mirroring
    Generate-BatchReport in the Windows script. Returns the report content."""
    completed = [j for j in jobs if j.status == "Completed"]
    errors = [j for j in jobs if j.status == "Error"]
    pending = [j for j in jobs if j.status == "Pending"]
    duration = (datetime.now() - batch_start_time).total_seconds()

    lines = [
        "=== TIFF Channel Merger - Batch Report ===",
        f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"Total duration: {duration:.1f}s",
        "",
        f"Jobs completed: {len(completed)} / {len(jobs)}",
        f"Errors: {len(errors)}",
        f"Pending (not run): {len(pending)}",
        "",
    ]

    for job in jobs:
        lines.append(f"[{job.status}] {job.job_name} -> {job.output_name}.tif ({job.duration_seconds():.1f}s)")
        if job.status == "Error" and job.error_message:
            lines.append(f"    Error: {job.error_message}")

    report = "\n".join(lines) + "\n"
    report_path = Path(output_dir) / "batch_report.txt"
    report_path.write_text(report, encoding="utf-8")
    return report
