# QuPath Channel Name Import Instructions (macOS)

## 🎯 Quick Start

When you merge TIFF channels using this application, **4 files** are created:

1. **`merged_channels.tif`** - Your multi-channel pyramidal TIFF image
2. **`merged_channels.ome.xml`** - OME metadata (contains channel information)
3. **`merged_channels_channels.txt`** - Simple list of channel names (one per line)
4. **`QuPath_Import_merged_channels.groovy`** - Automated script to import channel names into QuPath

## 📖 Method 1: Automated Import (Recommended)

### Step-by-step:

1. **Open QuPath** and load your merged TIFF file:
   - `File → Open...` → Select `merged_channels.tif`

2. **Set the image type to Fluorescence**:
   - `Image → Image type → Fluorescence`

3. **Open the Script Editor**:
   - `Automate → Show script editor`

4. **Load the auto-generated script**:
   - In the script editor: `File → Open script...`
   - Navigate to the folder containing your merged TIFF
   - Select `QuPath_Import_merged_channels.groovy`

5. **Run the script**:
   - Click the **Run** button (▶) or press `⌘+R` (Cmd+R)
   - The script will automatically read the channel names from `merged_channels_channels.txt`
   - Channel names will be applied to your image

6. **Verify**:
   - Open the **Brightness/Contrast** panel (View → Brightness/Contrast or `Shift+C`)
   - You should see your custom channel names instead of "Channel 0", "Channel 1", etc.

### Expected output in console:

```
Reading channel names from: merged_channels_channels.txt
Found 3 channels found:
  Channel 0: DAPI
  Channel 1: GFP
  Channel 2: RFP

✅ Channel names updated successfully!
The channel names should now appear in the Brightness/Contrast panel.
```

---

## 📖 Method 2: Manual Import

If the automated script doesn't work, you can manually rename channels:

1. Open your TIFF in QuPath
2. Set image type to **Fluorescence** (`Image → Image type → Fluorescence`)
3. Open **Brightness/Contrast** panel (`View → Brightness/Contrast` or `Shift+C`)
4. For each channel:
   - Right-click on the channel name
   - Select **Rename channel**
   - Enter the name from `merged_channels_channels.txt`

---

## 🔧 Troubleshooting

### Script Error: "Channel names file not found"

**Cause**: The script can't find the `_channels.txt` file

**Solution**:
- Make sure `merged_channels_channels.txt` is in the same folder as the TIFF
- If you moved the TIFF, move the `.txt` and `.groovy` files too
- The files must remain together in the same directory

### Script Error: "No image is currently open"

**Cause**: You need to open the TIFF image before running the script

**Solution**:
1. Open the merged TIFF in QuPath first (`File → Open...`)
2. Set image type to Fluorescence
3. Then run the script

### Channel count mismatch warning

**Cause**: The number of channels in the TIFF doesn't match the number of names in the text file

**Impact**: Some channels may not get renamed

**Solution**:
- Check that all source TIFF files were included in the merge
- Verify the `_channels.txt` file has the correct number of lines (one name per line)
- Re-run the merger if necessary

---

## 🧪 Advanced: About OME-XML Metadata

### Why sidecar files instead of embedded metadata?

For **large pyramidal TIFFs** (>1 GB), embedding OME-XML metadata directly into the TIFF file can be problematic:

- Some image libraries may need to reload the entire file
- The pyramidal structure could be affected
- File compatibility might be reduced

The **solution** used by this application:
- Use **sidecar files** (`.ome.xml` and `_channels.txt`) to store metadata separately
- Use a **QuPath Groovy script** to import the metadata safely
- The TIFF file remains intact with its pyramidal structure preserved
- This approach is **reliable** and works for files of any size

### Files created by TIFF Channel Merger:

| File | Purpose | QuPath Usage |
|------|---------|--------------|
| `*.tif` | Multi-channel pyramidal TIFF | Open in QuPath |
| `*.ome.xml` | OME metadata sidecar | Reference/documentation |
| `*_channels.txt` | Channel names (plain text) | Read by Groovy script |
| `QuPath_Import_*.groovy` | Import automation script | Run in QuPath script editor |

---

## 📚 File Format Reference

### OME-XML Format (.ome.xml)
- XML file following the OME-XML 2016-06 schema
- Contains complete image metadata: dimensions, channels, pixel types
- QuPath can read this but doesn't auto-import channel names from it

### Channel Names Format (_channels.txt)
- Plain text file (UTF-8 encoding)
- One channel name per line
- Example:
  ```
  DAPI
  GFP
  RFP
  Cy5
  ```

### QuPath Script Format (.groovy)
- Groovy script for QuPath's script editor
- Automatically generated with correct file paths
- Reads `_channels.txt` and applies names to image channels
- Bilingual comments (French/English) based on your interface language

---

## 🆘 Support & Diagnostics

If you encounter issues, the application creates diagnostic logs in the output folder:

- **`vips_output.log`** - VIPS standard output
- **`vips_error.log`** - VIPS error messages
- **`vips_diagnostic.log`** - Complete processing information

### Common Issues:

1. **Merge failed / Output file is empty**
   - Check `vips_error.log` for error messages
   - Verify VIPS is installed: `vips --version` in Terminal
   - Ensure input files are valid TIFF images

2. **Out of memory errors**
   - Close other applications
   - Process fewer channels at once
   - Use pyramidal TIFF option (recommended for large images)

3. **QuPath doesn't recognize channels**
   - Ensure image type is set to **Fluorescence**
   - Run the auto-generated Groovy script
   - Check that `_channels.txt` is in the same folder as the TIFF

4. **File paths with special characters**
   - Avoid accents, spaces, or special characters in folder names
   - Use simple ASCII characters for best compatibility

---

## 📄 License & Attribution

**TIFF Channel Merger for macOS**
- Copyright (c) 2024 Loïc Talignani & Céline Talignani
- Licensed under CC BY-NC-SA 4.0
- Free for academic and research use

**Third-Party Components:**
- **VIPS (libvips)** - Fast image processing library (LGPL 2.1+)
- **QuPath** - Bioimage analysis software (GPL-3.0)
- **Python/Tkinter** - GUI framework (PSF License)

---

**Version**: 4.0
**Platform**: macOS 10.12+ (Sierra and later)
