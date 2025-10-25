#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TIFF Channel Merger for macOS
Version 4.0 - Advanced GUI with channel ordering and naming
Python/Tkinter implementation for enhanced user experience

Copyright (c) 2024 Loïc Talignani & Céline Talignani

This work is licensed under the Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit:
http://creativecommons.org/licenses/by-nc-sa/4.0/
"""

import tkinter as tk
from tkinter import ttk, filedialog, messagebox, scrolledtext
import subprocess
import os
import sys
from pathlib import Path
import shutil

class TIFFChannelMerger:
    def __init__(self, root):
        self.root = root
        self.root.title("TIFF Channel Merger")
        self.root.geometry("850x700")

        # Variables
        self.language = tk.StringVar(value="")
        self.selected_files = []
        self.channel_names = []
        self.vips_path = ""

        # Texts
        self.texts = {}

        # Show language selection
        self.show_language_selection()

    def show_language_selection(self):
        """Language selection dialog"""
        lang_frame = ttk.Frame(self.root, padding="40")
        lang_frame.pack(expand=True)

        title = ttk.Label(lang_frame, text="🌍 Language Selection / Sélection de langue",
                         font=("Helvetica", 16, "bold"))
        title.pack(pady=20)

        desc = ttk.Label(lang_frame,
                        text="Choose your preferred language:\nChoisissez votre langue préférée:",
                        font=("Helvetica", 12))
        desc.pack(pady=10)

        btn_frame = ttk.Frame(lang_frame)
        btn_frame.pack(pady=20)

        ttk.Button(btn_frame, text="Français", width=15,
                  command=lambda: self.select_language("Français")).pack(side=tk.LEFT, padx=10)
        ttk.Button(btn_frame, text="English", width=15,
                  command=lambda: self.select_language("English")).pack(side=tk.LEFT, padx=10)

    def select_language(self, lang):
        """Initialize texts and check VIPS"""
        self.language.set(lang)
        self.init_texts(lang)

        # Clear language selection frame
        for widget in self.root.winfo_children():
            widget.destroy()

        # Check VIPS installation
        if not self.check_vips():
            messagebox.showerror(self.texts["error"], self.texts["vipsNotInstalled"])
            self.root.quit()
            return

        # Show welcome screen
        self.show_welcome()

    def init_texts(self, lang):
        """Initialize text strings based on language"""
        if lang == "Français":
            self.texts = {
                "appTitle": "Fusion de canaux TIFF",
                "error": "Erreur",
                "vipsNotInstalled": "VIPS n'est pas installé.\n\nInstallez-le avec:\nbrew install vips",
                "welcome": "Bienvenue dans le Fusionneur de canaux TIFF",
                "welcomeDesc": "Cette application permet de fusionner plusieurs fichiers TIFF\n(canaux de fluorescence) en un seul fichier multi-canal\noptimisé pour QuPath.",
                "start": "Commencer",
                "quit": "Quitter",
                "selectFiles": "Sélection des fichiers",
                "selectFilesDesc": "Sélectionnez au moins 2 fichiers TIFF à fusionner.\nL'ordre dans la liste détermine l'ordre des canaux:\n(le plus haut = Canal 1, le deuxième = Canal 2, etc.)\nUtilisez les boutons ▲/▼ pour réorganiser.",
                "addFile": "Ajouter des fichiers",
                "removeFile": "Supprimer",
                "moveUp": "▲ Monter",
                "moveDown": "▼ Descendre",
                "channelNaming": "Nommage des canaux",
                "channelNamingDesc": "Nommez chaque canal pour QuPath (optionnel):",
                "outputConfig": "Configuration de sortie",
                "outputName": "Nom du fichier (sans extension):",
                "outputLocation": "Emplacement:",
                "browse": "Parcourir...",
                "pyramidal": "Créer une image pyramidale",
                "pyramidalDesc": "(Recommandé pour les grandes images >10,000×10,000 px)",
                "continue": "Continuer",
                "cancel": "Annuler",
                "merge": "Fusionner",
                "back": "Retour",
                "minTwoFiles": "Vous devez sélectionner au moins 2 fichiers.",
                "invalidName": "Veuillez entrer un nom de fichier valide.",
                "selectOutput": "Veuillez sélectionner un dossier de sortie.",
                "merging": "Fusion en cours...",
                "mergingDesc": "Fusion des canaux TIFF. Veuillez patienter...",
                "success": "Succès!",
                "successDesc": "La fusion a été terminée avec succès!\n\nFichier créé:",
                "openFolder": "Ouvrir le dossier",
                "finish": "Terminer",
            }
        else:
            self.texts = {
                "appTitle": "TIFF Channel Merger",
                "error": "Error",
                "vipsNotInstalled": "VIPS is not installed.\n\nInstall it with:\nbrew install vips",
                "welcome": "Welcome to TIFF Channel Merger",
                "welcomeDesc": "This application allows you to merge multiple TIFF files\n(fluorescence channels) into a single multi-channel file\noptimized for QuPath.",
                "start": "Start",
                "quit": "Quit",
                "selectFiles": "File Selection",
                "selectFilesDesc": "Select at least 2 TIFF files to merge.\nThe order in the list determines the channel order:\n(top = Channel 1, second = Channel 2, etc.)\nUse ▲/▼ buttons to reorder.",
                "addFile": "Add Files",
                "removeFile": "Remove",
                "moveUp": "▲ Move Up",
                "moveDown": "▼ Move Down",
                "channelNaming": "Channel Naming",
                "channelNamingDesc": "Name each channel for QuPath (optional):",
                "outputConfig": "Output Configuration",
                "outputName": "File name (without extension):",
                "outputLocation": "Location:",
                "browse": "Browse...",
                "pyramidal": "Create pyramidal image",
                "pyramidalDesc": "(Recommended for large images >10,000×10,000 px)",
                "continue": "Continue",
                "cancel": "Cancel",
                "merge": "Merge",
                "back": "Back",
                "minTwoFiles": "You must select at least 2 files.",
                "invalidName": "Please enter a valid file name.",
                "selectOutput": "Please select an output folder.",
                "merging": "Merging...",
                "mergingDesc": "Merging TIFF channels. Please wait...",
                "success": "Success!",
                "successDesc": "Merge completed successfully!\n\nFile created:",
                "openFolder": "Open Folder",
                "finish": "Finish",
            }

    def check_vips(self):
        """Check if VIPS is installed"""
        possible_paths = [
            "/opt/homebrew/bin/vips",
            "/usr/local/bin/vips",
            "/opt/local/bin/vips"
        ]

        for path in possible_paths:
            if os.path.exists(path):
                try:
                    subprocess.run([path, "--version"], capture_output=True, check=True)
                    self.vips_path = path
                    return True
                except:
                    continue

        # Try finding it in PATH
        vips_path = shutil.which("vips")
        if vips_path:
            self.vips_path = vips_path
            return True

        return False

    def show_welcome(self):
        """Show welcome screen"""
        welcome_frame = ttk.Frame(self.root, padding="40")
        welcome_frame.pack(expand=True)

        title = ttk.Label(welcome_frame, text=self.texts["welcome"],
                         font=("Helvetica", 18, "bold"))
        title.pack(pady=20)

        desc = ttk.Label(welcome_frame, text=self.texts["welcomeDesc"],
                        font=("Helvetica", 12), justify=tk.CENTER)
        desc.pack(pady=20)

        btn_frame = ttk.Frame(welcome_frame)
        btn_frame.pack(pady=30)

        ttk.Button(btn_frame, text=self.texts["start"], width=15,
                  command=self.show_file_selection).pack(side=tk.LEFT, padx=10)
        ttk.Button(btn_frame, text=self.texts["quit"], width=15,
                  command=self.root.quit).pack(side=tk.LEFT, padx=10)

    def show_file_selection(self):
        """Show file selection screen with ordering and naming"""
        # Clear current content
        for widget in self.root.winfo_children():
            widget.destroy()

        main_frame = ttk.Frame(self.root, padding="20")
        main_frame.pack(fill=tk.BOTH, expand=True)

        # Title
        title = ttk.Label(main_frame, text=self.texts["selectFiles"],
                         font=("Helvetica", 16, "bold"))
        title.pack(pady=10)

        # Description
        desc = ttk.Label(main_frame, text=self.texts["selectFilesDesc"],
                        font=("Helvetica", 10), justify=tk.LEFT)
        desc.pack(pady=5)

        # File list with scrollbar
        list_frame = ttk.Frame(main_frame)
        list_frame.pack(fill=tk.BOTH, expand=True, pady=10)

        scrollbar = ttk.Scrollbar(list_frame)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self.file_listbox = tk.Listbox(list_frame, height=8, font=("Monaco", 11),
                                       yscrollcommand=scrollbar.set)
        self.file_listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.config(command=self.file_listbox.yview)

        # Buttons for file management
        btn_frame = ttk.Frame(main_frame)
        btn_frame.pack(pady=10)

        ttk.Button(btn_frame, text=self.texts["addFile"], width=15,
                  command=self.add_file).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text=self.texts["removeFile"], width=15,
                  command=self.remove_file).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text=self.texts["moveUp"], width=15,
                  command=self.move_up).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text=self.texts["moveDown"], width=15,
                  command=self.move_down).pack(side=tk.LEFT, padx=5)

        # Channel naming section
        naming_label = ttk.Label(main_frame, text=self.texts["channelNaming"],
                                font=("Helvetica", 14, "bold"))
        naming_label.pack(pady=(20, 5))

        naming_desc = ttk.Label(main_frame, text=self.texts["channelNamingDesc"],
                               font=("Helvetica", 10))
        naming_desc.pack(pady=5)

        # Channel naming frame with scrollbar
        self.naming_frame = ttk.Frame(main_frame)
        self.naming_frame.pack(fill=tk.BOTH, expand=True, pady=10)

        canvas = tk.Canvas(self.naming_frame, height=120)
        scrollbar_naming = ttk.Scrollbar(self.naming_frame, orient="vertical", command=canvas.yview)
        self.naming_inner_frame = ttk.Frame(canvas)

        self.naming_inner_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )

        canvas.create_window((0, 0), window=self.naming_inner_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar_naming.set)

        canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar_naming.pack(side=tk.RIGHT, fill=tk.Y)

        self.channel_entries = []

        # Navigation buttons
        nav_frame = ttk.Frame(main_frame)
        nav_frame.pack(pady=20)

        ttk.Button(nav_frame, text=self.texts["continue"], width=15,
                  command=self.show_output_config).pack(side=tk.LEFT, padx=10)
        ttk.Button(nav_frame, text=self.texts["cancel"], width=15,
                  command=self.root.quit).pack(side=tk.LEFT, padx=10)

    def add_file(self):
        """Add TIFF file to list"""
        file_path = filedialog.askopenfilename(
            title="Select TIFF file",
            filetypes=[("TIFF files", "*.tif *.tiff"), ("All files", "*.*")]
        )

        if file_path:
            self.selected_files.append(file_path)
            self.channel_names.append("")
            self.file_listbox.insert(tk.END, os.path.basename(file_path))
            self.update_channel_naming()

    def remove_file(self):
        """Remove selected file from list"""
        selection = self.file_listbox.curselection()
        if selection:
            index = selection[0]
            self.file_listbox.delete(index)
            del self.selected_files[index]
            del self.channel_names[index]
            self.update_channel_naming()

    def move_up(self):
        """Move selected file up in list"""
        selection = self.file_listbox.curselection()
        if selection and selection[0] > 0:
            index = selection[0]

            # Swap in listbox
            item = self.file_listbox.get(index)
            self.file_listbox.delete(index)
            self.file_listbox.insert(index - 1, item)
            self.file_listbox.selection_set(index - 1)

            # Swap in data
            self.selected_files[index], self.selected_files[index - 1] = \
                self.selected_files[index - 1], self.selected_files[index]
            self.channel_names[index], self.channel_names[index - 1] = \
                self.channel_names[index - 1], self.channel_names[index]

            self.update_channel_naming()

    def move_down(self):
        """Move selected file down in list"""
        selection = self.file_listbox.curselection()
        if selection and selection[0] < len(self.selected_files) - 1:
            index = selection[0]

            # Swap in listbox
            item = self.file_listbox.get(index)
            self.file_listbox.delete(index)
            self.file_listbox.insert(index + 1, item)
            self.file_listbox.selection_set(index + 1)

            # Swap in data
            self.selected_files[index], self.selected_files[index + 1] = \
                self.selected_files[index + 1], self.selected_files[index]
            self.channel_names[index], self.channel_names[index + 1] = \
                self.channel_names[index + 1], self.channel_names[index]

            self.update_channel_naming()

    def update_channel_naming(self):
        """Update channel naming entries"""
        # Clear existing entries
        for widget in self.naming_inner_frame.winfo_children():
            widget.destroy()

        self.channel_entries = []

        for i, file_path in enumerate(self.selected_files):
            frame = ttk.Frame(self.naming_inner_frame)
            frame.pack(fill=tk.X, pady=2)

            label_text = f"{i+1}. {os.path.basename(file_path)}"
            label = ttk.Label(frame, text=label_text, width=40)
            label.pack(side=tk.LEFT, padx=5)

            entry = ttk.Entry(frame, width=30)
            entry.insert(0, self.channel_names[i])
            entry.pack(side=tk.LEFT, padx=5)

            # Update channel name on change
            entry.bind("<KeyRelease>", lambda e, idx=i: self.update_channel_name(idx, e.widget.get()))

            self.channel_entries.append(entry)

    def update_channel_name(self, index, value):
        """Update channel name in list"""
        if index < len(self.channel_names):
            self.channel_names[index] = value

    def show_output_config(self):
        """Show output configuration screen"""
        if len(self.selected_files) < 2:
            messagebox.showwarning(self.texts["error"], self.texts["minTwoFiles"])
            return

        # Clear current content
        for widget in self.root.winfo_children():
            widget.destroy()

        main_frame = ttk.Frame(self.root, padding="40")
        main_frame.pack(expand=True)

        # Title
        title = ttk.Label(main_frame, text=self.texts["outputConfig"],
                         font=("Helvetica", 16, "bold"))
        title.pack(pady=20)

        # Output name
        name_frame = ttk.Frame(main_frame)
        name_frame.pack(pady=10, fill=tk.X)

        ttk.Label(name_frame, text=self.texts["outputName"],
                 font=("Helvetica", 12)).pack(anchor=tk.W, pady=5)
        self.output_name_var = tk.StringVar(value="merged_channels")
        ttk.Entry(name_frame, textvariable=self.output_name_var,
                 width=50, font=("Helvetica", 11)).pack(fill=tk.X, pady=5)

        # Output location
        location_frame = ttk.Frame(main_frame)
        location_frame.pack(pady=10, fill=tk.X)

        ttk.Label(location_frame, text=self.texts["outputLocation"],
                 font=("Helvetica", 12)).pack(anchor=tk.W, pady=5)

        loc_entry_frame = ttk.Frame(location_frame)
        loc_entry_frame.pack(fill=tk.X, pady=5)

        self.output_location_var = tk.StringVar(value=os.path.expanduser("~/Desktop"))
        ttk.Entry(loc_entry_frame, textvariable=self.output_location_var,
                 width=40, font=("Helvetica", 11)).pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 5))
        ttk.Button(loc_entry_frame, text=self.texts["browse"],
                  command=self.browse_output).pack(side=tk.LEFT)

        # Pyramid option
        pyramid_frame = ttk.Frame(main_frame)
        pyramid_frame.pack(pady=20)

        self.pyramid_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(pyramid_frame, text=self.texts["pyramidal"],
                       variable=self.pyramid_var).pack(anchor=tk.W)
        ttk.Label(pyramid_frame, text=self.texts["pyramidalDesc"],
                 font=("Helvetica", 10), foreground="gray").pack(anchor=tk.W, padx=20)

        # Buttons
        btn_frame = ttk.Frame(main_frame)
        btn_frame.pack(pady=30)

        ttk.Button(btn_frame, text=self.texts["merge"], width=15,
                  command=self.start_merge).pack(side=tk.LEFT, padx=10)
        ttk.Button(btn_frame, text=self.texts["back"], width=15,
                  command=self.show_file_selection).pack(side=tk.LEFT, padx=10)
        ttk.Button(btn_frame, text=self.texts["cancel"], width=15,
                  command=self.root.quit).pack(side=tk.LEFT, padx=10)

    def browse_output(self):
        """Browse for output folder"""
        folder = filedialog.askdirectory(initialdir=self.output_location_var.get())
        if folder:
            self.output_location_var.set(folder)

    def start_merge(self):
        """Start the merge process"""
        output_name = self.output_name_var.get().strip()
        output_location = self.output_location_var.get().strip()

        if not output_name:
            messagebox.showwarning(self.texts["error"], self.texts["invalidName"])
            return

        if not output_location or not os.path.isdir(output_location):
            messagebox.showwarning(self.texts["error"], self.texts["selectOutput"])
            return

        # Show progress
        self.show_progress()

        # Run merge in background
        self.root.after(100, lambda: self.perform_merge(output_name, output_location))

    def show_progress(self):
        """Show merge progress"""
        for widget in self.root.winfo_children():
            widget.destroy()

        progress_frame = ttk.Frame(self.root, padding="60")
        progress_frame.pack(expand=True)

        title = ttk.Label(progress_frame, text=self.texts["merging"],
                         font=("Helvetica", 16, "bold"))
        title.pack(pady=20)

        desc = ttk.Label(progress_frame, text=self.texts["mergingDesc"],
                        font=("Helvetica", 12))
        desc.pack(pady=10)

        self.progress_bar = ttk.Progressbar(progress_frame, mode='indeterminate', length=400)
        self.progress_bar.pack(pady=30)
        self.progress_bar.start(10)

    def perform_merge(self, output_name, output_location):
        """Perform the actual merge"""
        try:
            output_path = os.path.join(output_location, output_name)
            temp_file = output_path + "_temp.tif"
            final_file = output_path + ".tif"

            # Set environment variables for large image processing
            env = os.environ.copy()
            env['VIPS_DISC_THRESHOLD'] = '2g'  # Use disk when image exceeds 2GB
            env['VIPS_CONCURRENCY'] = '2'      # Allow some parallelism (2 threads)
            env['IM_CONCURRENCY'] = '2'        # ImageMagick compatibility
            env['VIPS_NOVECTOR'] = '1'         # Disable vector operations (more stable)
            env['LIBTIFF_WARNINGS'] = 'no'     # Suppress libtiff warnings

            # DIRECT APPROACH: Use bandjoin directly with increased memory limits
            # Much faster than converting each file first

            # Collect all logs for diagnostic purposes
            all_logs = []

            # Build file list for VIPS
            file_list = " ".join([f'"{f}"' for f in self.selected_files])

            # Step 1: Merge channels directly with bandjoin
            merge_cmd = f'{self.vips_path} bandjoin "{file_list}" "{temp_file}"'
            merge_result = subprocess.run(merge_cmd, shell=True, capture_output=True, text=True, env=env)
            all_logs.append(('merge', 0, merge_result))

            if merge_result.returncode != 0:
                raise Exception(f"Merge failed: {merge_result.stderr}")

            # Step 3: Create final file with disk-based processing
            if self.pyramid_var.get():
                save_cmd = f'{self.vips_path} tiffsave "{temp_file}" "{final_file}" --compression=lzw --tile --tile-width=256 --tile-height=256 --pyramid --bigtiff --vips-disc-threshold=0'
            else:
                save_cmd = f'{self.vips_path} tiffsave "{temp_file}" "{final_file}" --compression=lzw --bigtiff --vips-disc-threshold=0'

            save_result = subprocess.run(save_cmd, shell=True, capture_output=True, text=True, env=env)
            all_logs.append(('save', 0, save_result))

            if save_result.returncode != 0:
                raise Exception(f"Save failed: {save_result.stderr}")

            # Create OME-XML if channel names are provided
            has_channel_names = any(name.strip() for name in self.channel_names)
            if has_channel_names:
                self.create_ome_xml(final_file, output_path)

            # Copy VIPS logs to output directory for troubleshooting
            self.copy_logs_to_output(output_location, all_logs)

            # Clean up
            if os.path.exists(temp_file):
                os.remove(temp_file)

            # Show success
            self.show_success(final_file, output_location)

        except Exception as e:
            self.progress_bar.stop()
            messagebox.showerror(self.texts["error"], str(e))
            self.show_file_selection()

    def copy_logs_to_output(self, output_location, all_logs):
        """Copy VIPS logs to output directory for troubleshooting"""
        try:
            # Aggregate all stdout and stderr
            all_stdout = []
            all_stderr = []

            for step, index, result in all_logs:
                if result.stdout:
                    all_stdout.append(f"--- {step.upper()} {index if index > 0 else ''} ---\n{result.stdout}\n")
                if result.stderr:
                    all_stderr.append(f"--- {step.upper()} {index if index > 0 else ''} ---\n{result.stderr}\n")

            # Save VIPS logs
            if all_stdout:
                vips_log_path = os.path.join(output_location, "vips_output.log")
                with open(vips_log_path, 'w') as f:
                    f.write('\n'.join(all_stdout))
                print(f"  ✓ Saved vips_output.log")

            if all_stderr:
                vips_error_path = os.path.join(output_location, "vips_error.log")
                with open(vips_error_path, 'w') as f:
                    f.write('\n'.join(all_stderr))
                print(f"  ✓ Saved vips_error.log")

            # Create a diagnostic log with file information
            diagnostic_path = os.path.join(output_location, "vips_diagnostic.log")
            with open(diagnostic_path, 'w') as f:
                f.write("=== VIPS Diagnostic Log ===\n")
                f.write(f"VIPS Path: {self.vips_path}\n")
                f.write(f"Output Location: {output_location}\n\n")
                f.write("Selected Files:\n")
                for i, file_path in enumerate(self.selected_files):
                    channel_name = self.channel_names[i] if i < len(self.channel_names) and self.channel_names[i] else f"Channel_{i+1}"
                    f.write(f"  {i+1}. {channel_name}: {file_path}\n")
                f.write("\n")
                f.write("Processing Steps:\n")
                for step, index, result in all_logs:
                    f.write(f"\n{step.upper()} {index if index > 0 else ''}:\n")
                    if result.stdout:
                        f.write("Output:\n")
                        f.write(result.stdout)
                        f.write("\n")
                    if result.stderr:
                        f.write("Errors:\n")
                        f.write(result.stderr)
                        f.write("\n")
            print(f"  ✓ Saved vips_diagnostic.log")

        except Exception as e:
            print(f"  ⚠ Could not save logs: {e}")

    def create_ome_xml(self, tiff_file, output_base):
        """Create OME-XML sidecar file"""
        channel_count = len(self.selected_files)

        ome_xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<!-- Warning: this comment is an OME-XML metadata block, which contains crucial dimensional parameters and other important metadata. -->
<OME xmlns="http://www.openmicroscopy.org/Schemas/OME/2016-06"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="http://www.openmicroscopy.org/Schemas/OME/2016-06
                         http://www.openmicroscopy.org/Schemas/OME/2016-06/ome.xsd">
  <Image ID="Image:0" Name="merged_channels">
    <Pixels DimensionOrder="XYCZT" ID="Pixels:0" Type="uint16"
            SizeC="{channel_count}" SizeT="1" SizeX="1024" SizeY="1024" SizeZ="1">
'''

        for i, name in enumerate(self.channel_names):
            channel_name = name.strip() if name.strip() else f"Channel_{i+1}"
            # Escape XML special characters
            channel_name = channel_name.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            ome_xml += f'      <Channel ID="Channel:0:{i}" Name="{channel_name}"/>\n'

        ome_xml += f'''      <TiffData IFD="0" PlaneCount="{channel_count}"/>
    </Pixels>
  </Image>
</OME>'''

        ome_file = output_base + ".ome.xml"
        with open(ome_file, 'w', encoding='utf-8') as f:
            f.write(ome_xml)

    def show_success(self, final_file, output_location):
        """Show success message"""
        self.progress_bar.stop()

        for widget in self.root.winfo_children():
            widget.destroy()

        success_frame = ttk.Frame(self.root, padding="40")
        success_frame.pack(expand=True)

        title = ttk.Label(success_frame, text=self.texts["success"],
                         font=("Helvetica", 18, "bold"), foreground="green")
        title.pack(pady=20)

        desc = ttk.Label(success_frame,
                        text=f"{self.texts['successDesc']}\n\n{final_file}",
                        font=("Helvetica", 12), justify=tk.CENTER)
        desc.pack(pady=20)

        btn_frame = ttk.Frame(success_frame)
        btn_frame.pack(pady=30)

        ttk.Button(btn_frame, text=self.texts["openFolder"], width=15,
                  command=lambda: subprocess.run(["open", output_location])).pack(side=tk.LEFT, padx=10)
        ttk.Button(btn_frame, text=self.texts["finish"], width=15,
                  command=self.root.quit).pack(side=tk.LEFT, padx=10)


def main():
    root = tk.Tk()
    app = TIFFChannelMerger(root)
    root.mainloop()


if __name__ == "__main__":
    main()
