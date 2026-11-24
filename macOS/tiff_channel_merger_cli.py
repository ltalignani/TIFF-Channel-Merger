#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TIFF Channel Merger - macOS command-line interface.

Non-interactive CLI counterpart to tiff_channel_merger_gui.py, built for
scripting and automation. Feature parity with the current Windows version
(windows/TIFF-Channel-Merger.ps1): single merge + batch mode, pyramidal
LZW/BigTIFF output, QuPath Groovy import script generation. See
tiff_merger_core.py for the shared implementation and macOS/README-macOS.md
for usage.

Copyright (c) 2024 Loic Talignani & Celine Talignani
This work is licensed under the Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 International License.
"""

import argparse
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

import tiff_merger_core as core

MESSAGES = {
    "en": {
        "vips_not_found": "VIPS is not installed or could not be found.\nInstall it with: brew install vips",
        "vips_install_prompt": "VIPS is not installed. Install it now via Homebrew? [y/N]: ",
        "vips_installing": "Installing VIPS via Homebrew (this may take a few minutes)...",
        "vips_install_ok": "VIPS installed successfully.",
        "vips_install_failed": "Automatic installation failed:\n{err}\nInstall it manually with: brew install vips",
        "min_two_files": "At least 2 files are required to merge channels.",
        "merging": "Merging {n} channels into {out}...",
        "merge_ok": "Merge complete.",
        "merge_failed": "Merge failed: {err}",
        "files_created": "Files created:",
        "batch_loading": "Loading batch config: {path}",
        "batch_job_count": "{n} job(s) to process.",
        "batch_job_start": "[{i}/{n}] {name}: merging {count} channels...",
        "batch_job_ok": "[{i}/{n}] {name}: done ({dur:.1f}s)",
        "batch_job_error": "[{i}/{n}] {name}: ERROR - {err}",
        "batch_report": "Batch report written to: {path}",
        "batch_summary": "{completed}/{total} jobs completed, {errors} error(s).",
    },
    "fr": {
        "vips_not_found": "VIPS n'est pas installe ou introuvable.\nInstallez-le avec : brew install vips",
        "vips_install_prompt": "VIPS n'est pas installe. L'installer maintenant via Homebrew ? [o/N] : ",
        "vips_installing": "Installation de VIPS via Homebrew (cela peut prendre quelques minutes)...",
        "vips_install_ok": "VIPS installe avec succes.",
        "vips_install_failed": "L'installation automatique a echoue :\n{err}\nInstallez-le manuellement avec : brew install vips",
        "min_two_files": "Au moins 2 fichiers sont requis pour fusionner des canaux.",
        "merging": "Fusion de {n} canaux vers {out}...",
        "merge_ok": "Fusion terminee.",
        "merge_failed": "Echec de la fusion : {err}",
        "files_created": "Fichiers crees :",
        "batch_loading": "Chargement de la config batch : {path}",
        "batch_job_count": "{n} job(s) a traiter.",
        "batch_job_start": "[{i}/{n}] {name} : fusion de {count} canaux...",
        "batch_job_ok": "[{i}/{n}] {name} : termine ({dur:.1f}s)",
        "batch_job_error": "[{i}/{n}] {name} : ERREUR - {err}",
        "batch_report": "Rapport batch ecrit dans : {path}",
        "batch_summary": "{completed}/{total} jobs termines, {errors} erreur(s).",
    },
}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="tiff_channel_merger_cli.py",
        description="Merge single-channel TIFF files into a multi-channel TIFF optimized for QuPath.",
    )
    parser.add_argument("--lang", choices=["en", "fr"], default="en", help="Language for console messages (default: en).")
    subparsers = parser.add_subparsers(dest="command", required=True)

    merge_parser = subparsers.add_parser("merge", help="Merge a single set of channel files.")
    merge_parser.add_argument("--files", nargs="+", required=True, metavar="FILE",
                               help="TIFF files to merge, in channel order (first = Channel 1). At least 2 required.")
    merge_parser.add_argument("--names", nargs="*", default=None, metavar="NAME",
                               help="Channel names, matched positionally to --files. Optional; defaults to Channel_N.")
    merge_parser.add_argument("--output-name", required=True, help="Output file name, without extension.")
    merge_parser.add_argument("--output-dir", required=True, help="Output directory.")
    merge_parser.add_argument("--no-pyramid", action="store_true", help="Disable pyramidal TIFF generation (enabled by default).")
    merge_parser.add_argument("-y", "--yes", action="store_true",
                               help="Auto-confirm installing VIPS via Homebrew if it's missing, without prompting.")

    batch_parser = subparsers.add_parser("batch", help="Run a batch of merge jobs from a JSON config.")
    batch_parser.add_argument("--config", required=True, help="Path to a batch_jobs.json file (same schema as the Windows GUI).")
    batch_parser.add_argument("--no-pyramid", action="store_true", help="Disable pyramidal TIFF generation (enabled by default).")
    batch_parser.add_argument("--no-report", action="store_true", help="Skip writing batch_report.txt.")
    batch_parser.add_argument("-y", "--yes", action="store_true",
                               help="Auto-confirm installing VIPS via Homebrew if it's missing, without prompting.")

    return parser


def ensure_vips(args, texts) -> Optional[str]:
    """Find VIPS, offering to install it via Homebrew if missing.

    Prompts for confirmation unless --yes was passed; never prompts when
    stdin isn't a TTY (e.g. running from a script/CI), to avoid hanging.
    """
    vips_path = core.find_vips()
    if vips_path:
        return vips_path

    if not core.homebrew_available():
        print(texts["vips_not_found"], file=sys.stderr)
        return None

    if not args.yes:
        if not sys.stdin.isatty():
            print(texts["vips_not_found"], file=sys.stderr)
            return None
        answer = input(texts["vips_install_prompt"]).strip().lower()
        if answer not in ("y", "yes", "o", "oui"):
            print(texts["vips_not_found"], file=sys.stderr)
            return None

    print(texts["vips_installing"])
    result = core.install_vips_via_brew()
    if result.returncode != 0:
        print(texts["vips_install_failed"].format(err=result.stderr.strip()), file=sys.stderr)
        return None

    vips_path = core.find_vips()
    if not vips_path:
        print(texts["vips_not_found"], file=sys.stderr)
        return None

    print(texts["vips_install_ok"])
    return vips_path


def run_merge(args, texts) -> int:
    vips_path = ensure_vips(args, texts)
    if not vips_path:
        return 1

    if len(args.files) < 2:
        print(texts["min_two_files"], file=sys.stderr)
        return 1

    output_tif = str(Path(args.output_dir) / f"{args.output_name}.tif")
    print(texts["merging"].format(n=len(args.files), out=output_tif))

    try:
        created = core.process_merge_job(
            vips_path=vips_path,
            files=args.files,
            channel_names=args.names,
            output_name=args.output_name,
            output_dir=args.output_dir,
            pyramid=not args.no_pyramid,
        )
    except (core.MergeError, ValueError) as e:
        print(texts["merge_failed"].format(err=e), file=sys.stderr)
        return 1

    print(texts["merge_ok"])
    print(texts["files_created"])
    for label, path in created.items():
        if path:
            print(f"  - {path}")
    return 0


def run_batch(args, texts) -> int:
    vips_path = ensure_vips(args, texts)
    if not vips_path:
        return 1

    print(texts["batch_loading"].format(path=args.config))
    jobs = core.load_batch_config(args.config)
    pending_jobs = [j for j in jobs if j.status == "Pending"]
    print(texts["batch_job_count"].format(n=len(pending_jobs)))

    batch_start = datetime.now()
    output_dir = None

    for i, job in enumerate(pending_jobs, start=1):
        job.start_time = datetime.now()
        job.status = "Running"
        print(texts["batch_job_start"].format(i=i, n=len(pending_jobs), name=job.job_name, count=len(job.selected_files)))
        output_dir = job.output_path
        try:
            core.process_merge_job(
                vips_path=vips_path,
                files=job.selected_files,
                channel_names=job.channel_names,
                output_name=job.output_name,
                output_dir=job.output_path,
                pyramid=job.pyramid and not args.no_pyramid,
            )
            job.status = "Completed"
        except (core.MergeError, ValueError) as e:
            job.status = "Error"
            job.error_message = str(e)
        job.end_time = datetime.now()

        if job.status == "Completed":
            print(texts["batch_job_ok"].format(i=i, n=len(pending_jobs), name=job.job_name, dur=job.duration_seconds()))
        else:
            print(texts["batch_job_error"].format(i=i, n=len(pending_jobs), name=job.job_name, err=job.error_message), file=sys.stderr)

    completed = [j for j in pending_jobs if j.status == "Completed"]
    errors = [j for j in pending_jobs if j.status == "Error"]

    if not args.no_report and output_dir:
        report = core.generate_batch_report(pending_jobs, output_dir, batch_start)
        print(texts["batch_report"].format(path=str(Path(output_dir) / "batch_report.txt")))

    print(texts["batch_summary"].format(completed=len(completed), total=len(pending_jobs), errors=len(errors)))
    return 0 if not errors else 1


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    texts = MESSAGES[args.lang]

    if args.command == "merge":
        return run_merge(args, texts)
    if args.command == "batch":
        return run_batch(args, texts)

    parser.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
