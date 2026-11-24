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
from tkinter import ttk, filedialog, messagebox
import subprocess
import os
from pathlib import Path
import shutil
import threading
import queue
from datetime import datetime

import tiff_merger_core as core

class TIFFChannelMerger:
    def __init__(self, root):
        self.root = root
        self.root.title("TIFF Channel Merger")
        self.root.geometry("850x700")

        # Variables
        self.language = tk.StringVar(value="")
        self.lang_name = ""
        self.selected_files = []
        self.channel_names = []
        self.vips_path = ""

        # "single": normal merge-and-quit flow.
        # "batch_add" / "batch_edit": file selection / output config screens are
        # reused to build a core.BatchJob and return to the job manager instead
        # of merging immediately.
        self.mode = "single"
        self.batch_jobs = []
        self.batch_edit_index = None
        self._edit_output_name = ""
        self._edit_output_dir = ""
        self._edit_pyramid = True

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
        # Plain-string copy: worker threads must not touch Tk variables
        self.lang_name = lang
        self.init_texts(lang)

        # Clear language selection frame
        for widget in self.root.winfo_children():
            widget.destroy()

        # Check VIPS installation
        if not self.check_vips():
            self.offer_vips_install()
            return

        # Show welcome screen
        self.show_welcome()

    def offer_vips_install(self):
        """VIPS is missing: offer to install it via Homebrew, or show manual instructions."""
        if not core.homebrew_available():
            messagebox.showerror(self.texts["error"], self.texts["homebrewMissing"])
            self.root.quit()
            return

        if messagebox.askyesno(self.texts["error"], self.texts["vipsInstallPrompt"]):
            self.show_vips_install_progress()
            self.perform_vips_install()
        else:
            messagebox.showerror(self.texts["error"], self.texts["vipsNotInstalled"])
            self.root.quit()

    def show_vips_install_progress(self):
        """Show a progress screen while Homebrew installs VIPS"""
        for widget in self.root.winfo_children():
            widget.destroy()

        progress_frame = ttk.Frame(self.root, padding="60")
        progress_frame.pack(expand=True)

        title = ttk.Label(progress_frame, text=self.texts["vipsInstalling"],
                         font=("Helvetica", 16, "bold"))
        title.pack(pady=20)

        desc = ttk.Label(progress_frame, text=self.texts["vipsInstallingDesc"],
                        font=("Helvetica", 12))
        desc.pack(pady=10)

        progress_bar = ttk.Progressbar(progress_frame, mode='indeterminate', length=400)
        progress_bar.pack(pady=30)
        progress_bar.start(10)

    def perform_vips_install(self):
        """Run `brew install vips` in the background (keeps the progress bar
        animated), then re-check and either continue or bail out"""
        def on_done(result, error):
            for widget in self.root.winfo_children():
                widget.destroy()

            if error is None and result.returncode == 0 and self.check_vips():
                self.show_welcome()
            else:
                detail = str(error) if error else (result.stderr or result.stdout or "")
                messagebox.showerror(self.texts["error"],
                                     f"{self.texts['vipsInstallFailed']}\n\n{detail.strip()[-800:]}")
                self.root.quit()

        self.run_in_background(core.install_vips_via_brew, on_done)

    def init_texts(self, lang):
        """Initialize text strings based on language"""
        if lang == "Français":
            self.texts = {
                "appTitle": "Fusion de canaux TIFF",
                "error": "Erreur",
                "vipsNotInstalled": "VIPS n'est pas installé.\n\nInstallez-le avec:\nbrew install vips",
                "homebrewMissing": "VIPS n'est pas installé, et Homebrew non plus.\n\n1. Installez Homebrew : https://brew.sh\n2. Dans le Terminal : brew install vips\n3. Relancez TIFF Channel Merger.",
                "vipsInstallPrompt": "VIPS n'est pas installé.\n\nVoulez-vous l'installer maintenant via Homebrew ?\n(Cela peut prendre quelques minutes)",
                "vipsInstalling": "Installation de VIPS...",
                "vipsInstallingDesc": "Installation via Homebrew en cours. Veuillez patienter...",
                "vipsInstallFailed": "Échec de l'installation automatique de VIPS.\nInstallez-le manuellement avec: brew install vips",
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
                "batchMode": "Mode Batch",
                "batchJobManager": "Gestionnaire de jobs batch",
                "batchJobManagerDesc": "Configurez plusieurs fusions à traiter à la suite\n(par exemple : plusieurs lames de microscopie).",
                "addJob": "Ajouter un job",
                "editJob": "Modifier",
                "removeJob": "Supprimer",
                "saveBatchList": "💾 Sauvegarder la liste",
                "loadBatchList": "📂 Charger une liste",
                "runBatch": "▶ Lancer le batch",
                "backToWelcome": "Menu principal",
                "addToBatch": "Ajouter au batch",
                "updateBatchJob": "Mettre à jour le job",
                "colJobName": "Nom",
                "colChannels": "Canaux",
                "colOutput": "Sortie",
                "colStatus": "Statut",
                "statusPending": "En attente",
                "statusRunning": "En cours",
                "statusCompleted": "Terminé",
                "statusError": "Erreur",
                "noJobSelected": "Sélectionnez un job dans la liste.",
                "confirmRemoveJob": "Supprimer ce job de la liste ?",
                "noJobsToRun": "Ajoutez au moins un job avant de lancer le batch.",
                "batchProcessing": "Traitement du batch en cours...",
                "batchProcessingJob": "Job",
                "batchComplete": "Batch terminé !",
                "batchReportSaved": "Rapport enregistré dans :",
                "openLastFolder": "Ouvrir le dernier dossier",
                "backToJobList": "Liste des jobs",
                "batchSummary": "{completed} / {total} job(s) terminé(s), {errors} erreur(s).",
                "batchReportFailed": "Impossible d'écrire le rapport :",
                "duplicateOutput": "Un autre job écrit déjà dans ce fichier :\n{path}\n\nChoisissez un autre nom ou dossier.",
                "loadFailed": "Impossible de charger la liste de jobs :",
                "saveFailed": "Impossible de sauvegarder la liste de jobs :",
                "inputNotFound": "Fichier introuvable :",
                "outputDirMissing": "Dossier de sortie introuvable :",
            }
        else:
            self.texts = {
                "appTitle": "TIFF Channel Merger",
                "error": "Error",
                "vipsNotInstalled": "VIPS is not installed.\n\nInstall it with:\nbrew install vips",
                "homebrewMissing": "VIPS is not installed, and neither is Homebrew.\n\n1. Install Homebrew: https://brew.sh\n2. In the Terminal: brew install vips\n3. Restart TIFF Channel Merger.",
                "vipsInstallPrompt": "VIPS is not installed.\n\nInstall it now via Homebrew?\n(This may take a few minutes)",
                "vipsInstalling": "Installing VIPS...",
                "vipsInstallingDesc": "Installing via Homebrew. Please wait...",
                "vipsInstallFailed": "Automatic VIPS installation failed.\nInstall it manually with: brew install vips",
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
                "batchMode": "Batch Mode",
                "batchJobManager": "Batch Job Manager",
                "batchJobManagerDesc": "Configure multiple merges to process in sequence\n(e.g. multiple microscopy slides).",
                "addJob": "Add Job",
                "editJob": "Edit",
                "removeJob": "Remove",
                "saveBatchList": "💾 Save List",
                "loadBatchList": "📂 Load List",
                "runBatch": "▶ Run Batch",
                "backToWelcome": "Main Menu",
                "addToBatch": "Add to Batch",
                "updateBatchJob": "Update Job",
                "colJobName": "Name",
                "colChannels": "Channels",
                "colOutput": "Output",
                "colStatus": "Status",
                "statusPending": "Pending",
                "statusRunning": "Running",
                "statusCompleted": "Completed",
                "statusError": "Error",
                "noJobSelected": "Select a job from the list.",
                "confirmRemoveJob": "Remove this job from the list?",
                "noJobsToRun": "Add at least one job before running the batch.",
                "batchProcessing": "Batch processing in progress...",
                "batchProcessingJob": "Job",
                "batchComplete": "Batch complete!",
                "batchReportSaved": "Report saved to:",
                "openLastFolder": "Open Last Folder",
                "backToJobList": "Job List",
                "batchSummary": "{completed} / {total} job(s) completed, {errors} error(s).",
                "batchReportFailed": "Could not write the report:",
                "duplicateOutput": "Another job already writes to this file:\n{path}\n\nChoose another name or folder.",
                "loadFailed": "Could not load the job list:",
                "saveFailed": "Could not save the job list:",
                "inputNotFound": "File not found:",
                "outputDirMissing": "Output folder not found:",
            }

    def check_vips(self):
        """Check if VIPS is installed (Homebrew/MacPorts paths first, then PATH)"""
        vips_path = core.find_vips()
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
                  command=self.start_single_mode).pack(side=tk.LEFT, padx=10)
        ttk.Button(btn_frame, text=self.texts["batchMode"], width=15,
                  command=self.show_batch_job_manager).pack(side=tk.LEFT, padx=10)
        ttk.Button(btn_frame, text=self.texts["quit"], width=15,
                  command=self.root.quit).pack(side=tk.LEFT, padx=10)

    def start_single_mode(self):
        """Enter the normal single-merge flow"""
        self.mode = "single"
        self.reset_current_job()
        self.show_file_selection()

    def reset_current_job(self):
        """Clear the file list/channel names being edited (used before starting
        a new single merge, or before adding/editing a batch job)"""
        self.selected_files = []
        self.channel_names = []
        self._edit_output_name = ""
        self._edit_output_dir = ""
        self._edit_pyramid = True

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

        # Re-populate from state when editing an existing batch job
        for file_path in self.selected_files:
            self.file_listbox.insert(tk.END, os.path.basename(file_path))

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
        self.update_channel_naming()

        # Navigation buttons
        nav_frame = ttk.Frame(main_frame)
        nav_frame.pack(pady=20)

        cancel_command = self.show_batch_job_manager if self.mode != "single" else self.root.quit

        ttk.Button(nav_frame, text=self.texts["continue"], width=15,
                  command=self.show_output_config).pack(side=tk.LEFT, padx=10)
        ttk.Button(nav_frame, text=self.texts["cancel"], width=15,
                  command=cancel_command).pack(side=tk.LEFT, padx=10)

    def add_file(self):
        """Add TIFF file(s) to list - supports multiple selection"""
        file_paths = filedialog.askopenfilenames(
            title="Select TIFF file(s)",
            filetypes=[("TIFF files", "*.tif *.tiff"), ("All files", "*.*")]
        )

        if file_paths:
            for file_path in file_paths:
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
        self.output_name_var = tk.StringVar(value=self._edit_output_name or "merged_channels")
        ttk.Entry(name_frame, textvariable=self.output_name_var,
                 width=50, font=("Helvetica", 11)).pack(fill=tk.X, pady=5)

        # Output location
        location_frame = ttk.Frame(main_frame)
        location_frame.pack(pady=10, fill=tk.X)

        ttk.Label(location_frame, text=self.texts["outputLocation"],
                 font=("Helvetica", 12)).pack(anchor=tk.W, pady=5)

        loc_entry_frame = ttk.Frame(location_frame)
        loc_entry_frame.pack(fill=tk.X, pady=5)

        self.output_location_var = tk.StringVar(value=self._edit_output_dir or os.path.expanduser("~/Desktop"))
        ttk.Entry(loc_entry_frame, textvariable=self.output_location_var,
                 width=40, font=("Helvetica", 11)).pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 5))
        ttk.Button(loc_entry_frame, text=self.texts["browse"],
                  command=self.browse_output).pack(side=tk.LEFT)

        # Pyramid option
        pyramid_frame = ttk.Frame(main_frame)
        pyramid_frame.pack(pady=20)

        self.pyramid_var = tk.BooleanVar(value=self._edit_pyramid)
        ttk.Checkbutton(pyramid_frame, text=self.texts["pyramidal"],
                       variable=self.pyramid_var).pack(anchor=tk.W)
        ttk.Label(pyramid_frame, text=self.texts["pyramidalDesc"],
                 font=("Helvetica", 10), foreground="gray").pack(anchor=tk.W, padx=20)

        # Buttons
        btn_frame = ttk.Frame(main_frame)
        btn_frame.pack(pady=30)

        if self.mode == "batch_edit":
            primary_text, primary_command = self.texts["updateBatchJob"], self.save_batch_job
        elif self.mode == "batch_add":
            primary_text, primary_command = self.texts["addToBatch"], self.save_batch_job
        else:
            primary_text, primary_command = self.texts["merge"], self.start_merge

        cancel_command = self.show_batch_job_manager if self.mode != "single" else self.root.quit

        ttk.Button(btn_frame, text=primary_text, width=15,
                  command=primary_command).pack(side=tk.LEFT, padx=10)
        ttk.Button(btn_frame, text=self.texts["back"], width=15,
                  command=self.show_file_selection).pack(side=tk.LEFT, padx=10)
        ttk.Button(btn_frame, text=self.texts["cancel"], width=15,
                  command=cancel_command).pack(side=tk.LEFT, padx=10)

    def browse_output(self):
        """Browse for output folder"""
        folder = filedialog.askdirectory(initialdir=self.output_location_var.get())
        if folder:
            self.output_location_var.set(folder)

    def validate_output(self):
        """Read and check the output name/folder fields. Returns (name, folder) or None."""
        output_name = self.output_name_var.get().strip()
        output_location = self.output_location_var.get().strip()

        if not output_name:
            messagebox.showwarning(self.texts["error"], self.texts["invalidName"])
            return None

        if not output_location or not os.path.isdir(output_location):
            messagebox.showwarning(self.texts["error"], self.texts["selectOutput"])
            return None

        return output_name, output_location

    def run_in_background(self, work, on_done):
        """Run work() in a worker thread so the window stays responsive, then call
        on_done(result, error) back on the Tk main thread (Tk is not thread-safe)."""
        result_queue = queue.Queue()

        def worker():
            try:
                result_queue.put((work(), None))
            except Exception as e:  # reported to the user by on_done
                result_queue.put((None, e))

        def poll():
            try:
                result, error = result_queue.get_nowait()
            except queue.Empty:
                self.root.after(200, poll)
                return
            on_done(result, error)

        threading.Thread(target=worker, daemon=True).start()
        self.root.after(200, poll)

    def start_merge(self):
        """Start the merge process"""
        validated = self.validate_output()
        if not validated:
            return
        output_name, output_location = validated

        # Snapshot the job so the worker thread never reads Tk state
        files = list(self.selected_files)
        names = list(self.channel_names)
        pyramid = self.pyramid_var.get()

        self.show_progress()

        def on_done(final_file, error):
            if error:
                self.progress_bar.stop()
                messagebox.showerror(self.texts["error"], str(error))
                self.show_file_selection()
            else:
                self.show_success(final_file, output_location)

        self.run_in_background(
            lambda: self.execute_merge(files, names, output_name, output_location, pyramid),
            on_done)

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

    def execute_merge(self, files, channel_names, output_name, output_location, pyramid):
        """Run one merge job (VIPS + OME-XML/QuPath files + logs).

        Runs in a worker thread: must not touch any Tk widget or variable.
        Returns the final TIFF path; raises on failure.
        """
        if len(files) < 2:
            raise ValueError(self.texts["minTwoFiles"])
        for file_path in files:
            if not os.path.isfile(file_path):
                raise FileNotFoundError(f"{self.texts['inputNotFound']} {file_path}")
        if not os.path.isdir(output_location):
            raise FileNotFoundError(f"{self.texts['outputDirMissing']} {output_location}")

        # Pad names so a job loaded from JSON with fewer names than files still works
        channel_names = list(channel_names) + [""] * (len(files) - len(channel_names))

        output_path = os.path.join(output_location, output_name)
        temp_file = output_path + "_temp.tif"
        final_file = output_path + ".tif"

        try:

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
            file_list = " ".join([f'"{f}"' for f in files])

            # Step 1: Merge channels directly with bandjoin
            merge_cmd = f'{self.vips_path} bandjoin "{file_list}" "{temp_file}"'
            merge_result = subprocess.run(merge_cmd, shell=True, capture_output=True, text=True, env=env)
            all_logs.append(('merge', 0, merge_result))

            if merge_result.returncode != 0:
                raise Exception(f"Merge failed: {merge_result.stderr}")

            # Step 3: Create final file with disk-based processing
            if pyramid:
                save_cmd = f'{self.vips_path} tiffsave "{temp_file}" "{final_file}" --compression=lzw --tile --tile-width=256 --tile-height=256 --pyramid --bigtiff --vips-disc-threshold=0'
            else:
                save_cmd = f'{self.vips_path} tiffsave "{temp_file}" "{final_file}" --compression=lzw --bigtiff --vips-disc-threshold=0'

            save_result = subprocess.run(save_cmd, shell=True, capture_output=True, text=True, env=env)
            all_logs.append(('save', 0, save_result))

            if save_result.returncode != 0:
                raise Exception(f"Save failed: {save_result.stderr}")

            # Create OME-XML if channel names are provided
            has_channel_names = any(name.strip() for name in channel_names)
            if has_channel_names:
                self.create_ome_xml(final_file, output_path, files, channel_names)

            # Copy VIPS logs to output directory for troubleshooting
            self.copy_logs_to_output(output_location, all_logs, files, channel_names)

            return final_file

        finally:
            # Clean up the intermediate file, on success and on failure
            if os.path.exists(temp_file):
                os.remove(temp_file)

    def copy_logs_to_output(self, output_location, all_logs, files, channel_names):
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
                for i, file_path in enumerate(files):
                    channel_name = channel_names[i] if i < len(channel_names) and channel_names[i] else f"Channel_{i+1}"
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

    def create_ome_xml(self, tiff_file, output_base, files, channel_names):
        """Create OME-XML sidecar file and QuPath import files"""
        channel_count = len(files)

        # Prepare channel names list
        channel_names_list = []
        for i, name in enumerate(channel_names[:channel_count]):
            channel_name = name.strip() if name.strip() else f"Channel_{i+1}"
            channel_names_list.append(channel_name)

        # 1. Create OME-XML sidecar file
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

        for i, channel_name in enumerate(channel_names_list):
            # Escape XML special characters
            channel_name_escaped = channel_name.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            ome_xml += f'      <Channel ID="Channel:0:{i}" Name="{channel_name_escaped}"/>\n'

        ome_xml += f'''      <TiffData IFD="0" PlaneCount="{channel_count}"/>
    </Pixels>
  </Image>
</OME>'''

        ome_file = output_base + ".ome.xml"
        with open(ome_file, 'w', encoding='utf-8') as f:
            f.write(ome_xml)

        # 2. Create channel names text file (for QuPath script)
        channels_txt_file = output_base + "_channels.txt"
        with open(channels_txt_file, 'w', encoding='utf-8') as f:
            for channel_name in channel_names_list:
                f.write(channel_name + '\n')

        # 3. Create QuPath Groovy import script
        self.create_qupath_script(output_base, channels_txt_file)

    def create_qupath_script(self, output_base, channels_txt_file):
        """Create QuPath Groovy script for importing channel names"""
        script_filename = f"QuPath_Import_{os.path.basename(output_base)}.groovy"
        script_path = os.path.join(os.path.dirname(output_base), script_filename)

        # Get relative path to channels.txt file (in same directory)
        channels_txt_basename = os.path.basename(channels_txt_file)

        # Determine language for comments
        is_french = self.lang_name == "Français"

        if is_french:
            comment_header = "// Script QuPath - Importation automatique des noms de canaux"
            comment_generated = "// Généré automatiquement par TIFF Channel Merger"
            comment_instructions = """// INSTRUCTIONS D'UTILISATION :
// 1. Ouvrez votre image fusionnée dans QuPath
// 2. Définissez le type d'image : Image → Type d'image → Fluorescence
// 3. Ouvrez l'éditeur de script : Automatiser → Afficher l'éditeur de script
// 4. Ouvrez ce script : Fichier → Ouvrir le script...
// 5. Exécutez le script : Cliquez sur Exécuter (▶) ou appuyez sur Ctrl+R"""
            msg_reading = "Lecture des noms de canaux depuis"
            msg_found = "canaux trouvés"
            msg_channel = "Canal"
            msg_success = "✅ Noms de canaux mis à jour avec succès !"
            msg_verify = "Les noms de canaux devraient maintenant apparaître dans le panneau Luminosité/Contraste."
            msg_error_file = "❌ ERREUR : Impossible de trouver le fichier"
            msg_error_verify = "Vérifiez que le fichier est dans le même dossier que ce script."
            msg_error_no_image = "❌ ERREUR : Aucune image n'est ouverte dans QuPath."
            msg_error_open = "Veuillez d'abord ouvrir votre image fusionnée."
        else:
            comment_header = "// QuPath Script - Automatic channel name import"
            comment_generated = "// Auto-generated by TIFF Channel Merger"
            comment_instructions = """// USAGE INSTRUCTIONS:
// 1. Open your merged image in QuPath
// 2. Set image type: Image → Image type → Fluorescence
// 3. Open script editor: Automate → Show script editor
// 4. Open this script: File → Open script...
// 5. Run the script: Click Run (▶) or press Ctrl+R"""
            msg_reading = "Reading channel names from"
            msg_found = "channels found"
            msg_channel = "Channel"
            msg_success = "✅ Channel names updated successfully!"
            msg_verify = "The channel names should now appear in the Brightness/Contrast panel."
            msg_error_file = "❌ ERROR: Could not find file"
            msg_error_verify = "Make sure the file is in the same folder as this script."
            msg_error_no_image = "❌ ERROR: No image is open in QuPath."
            msg_error_open = "Please open your merged image first."

        groovy_script = f'''import qupath.lib.images.servers.ImageServerMetadata
import qupath.lib.images.servers.ImageChannel
import java.awt.Color

{comment_header}
{comment_generated}
{comment_instructions}

def imageData = getCurrentImageData()
if (imageData == null) {{
    println("{msg_error_no_image}")
    println("{msg_error_open}")
    return
}}

def server = imageData.getServer()
def scriptDir = new File(getClass().protectionDomain.codeSource.location.path).parent
def channelFile = new File(scriptDir, "{channels_txt_basename}")

if (!channelFile.exists()) {{
    println("{msg_error_file}: " + channelFile.absolutePath)
    println("{msg_error_verify}")
    return
}}

println("{msg_reading}: " + channelFile.name)
def channelNames = channelFile.readLines()
    .collect {{ it.trim() }}
    .findAll {{ !it.isEmpty() }}

println("Found " + channelNames.size() + " {msg_found}:")
channelNames.eachWithIndex {{ name, idx ->
    println("  {msg_channel} " + idx + ": " + name)
}}

def channels = []
channelNames.eachWithIndex {{ name, idx ->
    channels << ImageChannel.getInstance(name, Color.WHITE)
}}

def metadata = server.getMetadata()
def updatedMetadata = new ImageServerMetadata.Builder(metadata)
    .channels(channels)
    .build()

imageData.updateServerMetadata(updatedMetadata)

println()
println("{msg_success}")
println("{msg_verify}")
'''

        with open(script_path, 'w', encoding='utf-8') as f:
            f.write(groovy_script)

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

    # ------------------------------------------------------------------
    # Batch mode
    # ------------------------------------------------------------------

    def build_batch_tree(self, parent, height):
        """Create the job table (name / channels / output / status) used by the
        job manager and the batch processing screens"""
        tree_frame = ttk.Frame(parent)
        tree_frame.pack(fill=tk.BOTH, expand=True, pady=10)

        columns = ("name", "channels", "output", "status")
        self.batch_tree = ttk.Treeview(tree_frame, columns=columns, show="headings",
                                       height=height, selectmode="browse")
        headings = {"name": "colJobName", "channels": "colChannels",
                    "output": "colOutput", "status": "colStatus"}
        widths = {"name": 170, "channels": 70, "output": 380, "status": 100}
        for col in columns:
            self.batch_tree.heading(col, text=self.texts[headings[col]])
            anchor = tk.CENTER if col in ("channels", "status") else tk.W
            self.batch_tree.column(col, width=widths[col], anchor=anchor,
                                   stretch=(col == "output"))

        scrollbar = ttk.Scrollbar(tree_frame, orient="vertical", command=self.batch_tree.yview)
        self.batch_tree.configure(yscrollcommand=scrollbar.set)
        self.batch_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self.refresh_batch_tree()

    def refresh_batch_tree(self):
        """Redraw the job table from self.batch_jobs (row iid = job index)"""
        status_keys = {"Pending": "statusPending", "Running": "statusRunning",
                       "Completed": "statusCompleted", "Error": "statusError"}
        selection = self.batch_tree.selection()
        self.batch_tree.delete(*self.batch_tree.get_children())
        for i, job in enumerate(self.batch_jobs):
            output = os.path.join(job.output_path, f"{job.output_name}.tif")
            status = self.texts[status_keys.get(job.status, "statusPending")]
            self.batch_tree.insert("", tk.END, iid=str(i),
                                   values=(job.job_name, len(job.selected_files), output, status))
        for iid in selection:
            if self.batch_tree.exists(iid):
                self.batch_tree.selection_set(iid)

    def selected_batch_index(self):
        """Index of the job selected in the table, or None (with a warning)"""
        selection = self.batch_tree.selection()
        if not selection:
            messagebox.showwarning(self.texts["error"], self.texts["noJobSelected"])
            return None
        return int(selection[0])

    def show_batch_job_manager(self):
        """Batch job manager: build, edit, save/load and run a list of merges"""
        self.mode = "batch"
        self.batch_edit_index = None

        for widget in self.root.winfo_children():
            widget.destroy()

        main_frame = ttk.Frame(self.root, padding="20")
        main_frame.pack(fill=tk.BOTH, expand=True)

        ttk.Label(main_frame, text=self.texts["batchJobManager"],
                  font=("Helvetica", 16, "bold")).pack(pady=10)
        ttk.Label(main_frame, text=self.texts["batchJobManagerDesc"],
                  font=("Helvetica", 11), justify=tk.CENTER).pack(pady=5)

        self.build_batch_tree(main_frame, height=12)
        self.batch_tree.bind("<Double-1>", lambda e: self.edit_batch_job())

        job_btns = ttk.Frame(main_frame)
        job_btns.pack(pady=5)
        ttk.Button(job_btns, text=self.texts["addJob"], width=15,
                   command=self.add_batch_job).pack(side=tk.LEFT, padx=5)
        ttk.Button(job_btns, text=self.texts["editJob"], width=15,
                   command=self.edit_batch_job).pack(side=tk.LEFT, padx=5)
        ttk.Button(job_btns, text=self.texts["removeJob"], width=15,
                   command=self.remove_batch_job).pack(side=tk.LEFT, padx=5)

        file_btns = ttk.Frame(main_frame)
        file_btns.pack(pady=5)
        ttk.Button(file_btns, text=self.texts["saveBatchList"], width=22,
                   command=self.save_batch_list).pack(side=tk.LEFT, padx=5)
        ttk.Button(file_btns, text=self.texts["loadBatchList"], width=22,
                   command=self.load_batch_list).pack(side=tk.LEFT, padx=5)

        nav_btns = ttk.Frame(main_frame)
        nav_btns.pack(pady=15)
        ttk.Button(nav_btns, text=self.texts["runBatch"], width=18,
                   command=self.run_batch).pack(side=tk.LEFT, padx=10)
        ttk.Button(nav_btns, text=self.texts["backToWelcome"], width=18,
                   command=self.back_to_welcome).pack(side=tk.LEFT, padx=10)

    def back_to_welcome(self):
        """Leave the batch manager (the job list is kept in memory)"""
        for widget in self.root.winfo_children():
            widget.destroy()
        self.show_welcome()

    def add_batch_job(self):
        """Reuse the file selection / output screens to build a new job"""
        self.mode = "batch_add"
        self.batch_edit_index = None
        self.reset_current_job()
        # Convenience: new jobs default to the previous job's output folder
        if self.batch_jobs:
            self._edit_output_dir = self.batch_jobs[-1].output_path
        self.show_file_selection()

    def edit_batch_job(self):
        """Load the selected job into the file selection / output screens"""
        index = self.selected_batch_index()
        if index is None:
            return
        job = self.batch_jobs[index]

        self.mode = "batch_edit"
        self.batch_edit_index = index
        self.selected_files = list(job.selected_files)
        names = list(job.channel_names)
        self.channel_names = (names + [""] * len(self.selected_files))[:len(self.selected_files)]
        self._edit_output_name = job.output_name
        self._edit_output_dir = job.output_path
        self._edit_pyramid = job.pyramid
        self.show_file_selection()

    def remove_batch_job(self):
        index = self.selected_batch_index()
        if index is None:
            return
        if messagebox.askyesno(self.texts["removeJob"], self.texts["confirmRemoveJob"]):
            del self.batch_jobs[index]
            self.batch_tree.selection_remove(*self.batch_tree.selection())
            self.refresh_batch_tree()

    def save_batch_job(self):
        """'Add to Batch' / 'Update Job' button of the output configuration screen"""
        validated = self.validate_output()
        if not validated:
            return
        output_name, output_location = validated

        # Two jobs writing the same TIFF would silently overwrite each other
        target = os.path.normpath(os.path.join(output_location, output_name))
        for i, other in enumerate(self.batch_jobs):
            if i == self.batch_edit_index:
                continue
            if os.path.normpath(os.path.join(other.output_path, other.output_name)) == target:
                messagebox.showwarning(self.texts["error"],
                                       self.texts["duplicateOutput"].format(path=target + ".tif"))
                return

        job = core.BatchJob(
            job_name=output_name,
            selected_files=list(self.selected_files),
            channel_names=list(self.channel_names),
            output_name=output_name,
            output_path=output_location,
            pyramid=self.pyramid_var.get(),
        )

        if self.mode == "batch_edit" and self.batch_edit_index is not None:
            self.batch_jobs[self.batch_edit_index] = job
        else:
            self.batch_jobs.append(job)

        self.show_batch_job_manager()

    def save_batch_list(self):
        """Save the job list as JSON (same schema as the Windows GUI and the CLI)"""
        if not self.batch_jobs:
            messagebox.showwarning(self.texts["error"], self.texts["noJobsToRun"])
            return
        path = filedialog.asksaveasfilename(
            defaultextension=".json", initialfile="batch_jobs.json",
            filetypes=[("JSON", "*.json"), ("All files", "*.*")])
        if not path:
            return
        try:
            core.save_batch_config(path, self.batch_jobs)
        except OSError as e:
            messagebox.showerror(self.texts["error"], f"{self.texts['saveFailed']}\n{e}")

    def load_batch_list(self):
        """Load a batch_jobs.json (from this GUI, the CLI or the Windows version).
        Replaces the current list."""
        path = filedialog.askopenfilename(
            filetypes=[("JSON", "*.json"), ("All files", "*.*")])
        if not path:
            return
        try:
            jobs = core.load_batch_config(path)
        except (OSError, ValueError, AttributeError, TypeError) as e:
            messagebox.showerror(self.texts["error"], f"{self.texts['loadFailed']}\n{e}")
            return
        self.batch_jobs = jobs
        self.refresh_batch_tree()

    def run_batch(self):
        """Run every job in the list, one after the other"""
        if not self.batch_jobs:
            messagebox.showwarning(self.texts["error"], self.texts["noJobsToRun"])
            return

        for job in self.batch_jobs:
            job.status = "Pending"
            job.error_message = ""
            job.start_time = None
            job.end_time = None

        self.batch_start_time = datetime.now()
        self.show_batch_processing()
        self.run_next_batch_job(0)

    def show_batch_processing(self):
        """Progress screen: overall progress bar + live job table"""
        for widget in self.root.winfo_children():
            widget.destroy()

        main_frame = ttk.Frame(self.root, padding="20")
        main_frame.pack(fill=tk.BOTH, expand=True)

        self.batch_title = ttk.Label(main_frame, text=self.texts["batchProcessing"],
                                     font=("Helvetica", 16, "bold"))
        self.batch_title.pack(pady=10)

        self.batch_job_label = ttk.Label(main_frame, text="", font=("Helvetica", 12),
                                         justify=tk.CENTER)
        self.batch_job_label.pack(pady=5)

        self.batch_progress = ttk.Progressbar(main_frame, mode="determinate", length=500,
                                              maximum=len(self.batch_jobs))
        self.batch_progress.pack(pady=10)

        self.build_batch_tree(main_frame, height=10)

        # Filled in by finish_batch()
        self.batch_btn_frame = ttk.Frame(main_frame)
        self.batch_btn_frame.pack(pady=15)

    def run_next_batch_job(self, index):
        if index >= len(self.batch_jobs):
            self.finish_batch()
            return

        job = self.batch_jobs[index]
        job.status = "Running"
        job.start_time = datetime.now()
        self.batch_job_label.config(
            text=f"{self.texts['batchProcessingJob']} {index + 1}/{len(self.batch_jobs)} : {job.job_name}")
        self.refresh_batch_tree()

        def on_done(_final_file, error):
            job.end_time = datetime.now()
            if error:
                job.status = "Error"
                job.error_message = str(error).strip()
            else:
                job.status = "Completed"
            self.batch_progress["value"] = index + 1
            self.refresh_batch_tree()
            self.run_next_batch_job(index + 1)

        self.run_in_background(
            lambda: self.execute_merge(job.selected_files, job.channel_names,
                                       job.output_name, job.output_path, job.pyramid),
            on_done)

    def finish_batch(self):
        """Write batch_report.txt (in the first job's folder, like Windows) and show a summary"""
        completed = [j for j in self.batch_jobs if j.status == "Completed"]
        errors = [j for j in self.batch_jobs if j.status == "Error"]

        summary = self.texts["batchSummary"].format(
            completed=len(completed), total=len(self.batch_jobs), errors=len(errors))

        report_dir = self.batch_jobs[0].output_path
        try:
            core.generate_batch_report(self.batch_jobs, report_dir, self.batch_start_time)
            summary += f"\n{self.texts['batchReportSaved']} {os.path.join(report_dir, 'batch_report.txt')}"
        except OSError as e:
            summary += f"\n{self.texts['batchReportFailed']} {e}"

        for job in errors:
            first_line = job.error_message.splitlines()[0] if job.error_message else ""
            summary += f"\n• {job.job_name}: {first_line[:150]}"

        self.batch_title.config(text=self.texts["batchComplete"],
                                foreground="green" if not errors else "orange")
        self.batch_job_label.config(text=summary)

        last_folder = self.batch_jobs[-1].output_path
        ttk.Button(self.batch_btn_frame, text=self.texts["openLastFolder"], width=22,
                   command=lambda: subprocess.run(["open", last_folder])).pack(side=tk.LEFT, padx=5)
        ttk.Button(self.batch_btn_frame, text=self.texts["backToJobList"], width=18,
                   command=self.show_batch_job_manager).pack(side=tk.LEFT, padx=5)
        ttk.Button(self.batch_btn_frame, text=self.texts["finish"], width=15,
                   command=self.root.quit).pack(side=tk.LEFT, padx=5)


def main():
    root = tk.Tk()
    app = TIFFChannelMerger(root)
    root.mainloop()


if __name__ == "__main__":
    main()
