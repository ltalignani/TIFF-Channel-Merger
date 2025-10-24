# QuPath Channel Name Import Instructions

## 🎯 Quick Start

When you merge TIFF channels using this application, 4 files are created:

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
   - Click the **Run** button (▶) or press `Ctrl+R`
   - The script will automatically read the channel names from `merged_channels_channels.txt`
   - Channel names will be applied to your image

6. **Verify**:
   - Open the **Brightness/Contrast** panel
   - You should see your custom channel names instead of "Channel 0", "Channel 1", etc.

### Expected output in console:
```
Found 3 channel names:
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
2. Set image type to **Fluorescence**
3. Open **Brightness/Contrast** panel
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
- If you moved the TIFF, move the `.txt` file too
- Edit the `.groovy` script and update the file path on line 12

### Script Error: "No image is currently open"

**Cause**: You need to open the TIFF image before running the script

**Solution**:
1. Open the merged TIFF in QuPath first
2. Then run the script

### Channel count mismatch warning

**Cause**: The number of channels in the TIFF doesn't match the number of names in the text file

**Impact**: Some channels may not get renamed

**Solution**:
- Check that all source TIFF files were included in the merge
- Verify the `_channels.txt` file has the correct number of lines

---

## 🧪 Advanced: Why isn't OME-XML embedded in the TIFF?

For **large pyramidal TIFFs** (>1 GB), embedding OME-XML metadata directly into the TIFF file can cause **file corruption** because:

- Python libraries like `tifffile` and `Pillow` load the **entire file into memory** (7+ GB!)
- When rewriting the file, they destroy the pyramidal structure
- This results in empty or corrupted TIFF files

The **solution** used by this application:
- Use **sidecar files** (`.ome.xml` and `_channels.txt`) to store metadata
- Use a **QuPath script** to import the metadata safely
- The TIFF file remains intact and pyramidal structure is preserved

### Optional: Enable OME-XML embedding with tifftools

If you want OME-XML embedded directly in the TIFF (so QuPath auto-recognizes channels), you can install `tifftools`:

```bash
pip install tifftools
```

Then edit `TIFF-Channel-Merger.ps1` and uncomment the tifftools section (lines 1216-1235).

**Note**: `tifftools` is the **only** Python library that can safely modify large pyramidal TIFFs without loading them entirely in memory.

---

## 📚 File Format Reference

### OME-XML Format (.ome.xml)
- XML file following the OME-XML 2016-06 schema
- Contains complete image metadata: dimensions, channels, pixel types
- QuPath can read this but doesn't auto-import it

### Channel Names Format (_channels.txt)
- Plain text file
- One channel name per line
- UTF-8 encoding
- Example:
  ```
  DAPI
  GFP
  RFP
  ```

### QuPath Script Format (.groovy)
- Groovy script for QuPath's script editor
- Automatically generated with correct file paths
- Reads `_channels.txt` and applies names to channels

---

## 🆘 Support

If you encounter issues:

1. Check the log files created in the output folder:
   - `vips_diagnostic.log`
   - `vips_output.log`
   - `vips_save.log`

2. Verify file sizes:
   - If the final `.tif` is 0 bytes or very small, the merge failed
   - Check the log files for error messages

3. Common issues:
   - **Out of memory**: Close other applications, process fewer channels at once
   - **File paths with special characters**: Use simple folder names without accents or spaces
   - **Very large images (>50,000×50,000 pixels)**: May require increasing system virtual memory

---

## 📄 License & Attribution

This application uses:
- **libvips** - Fast image processing library (LGPL)
- **PowerShell** - Windows automation (MIT)
- **QuPath** - Bioimage analysis (GPLv3)

Generated by **TIFF Channel Merger** v3.10
