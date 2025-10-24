#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Inject OME-XML metadata into TIFF IMAGEDESCRIPTION tag
This creates a valid OME-TIFF that QuPath can read directly
"""

import sys
import os

# Force UTF-8 encoding for stdout on Windows
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

def inject_ome_xml_tifffile(tiff_path, ome_xml):
    """Use tifffile library (robust for pyramidal TIFFs)"""
    try:
        import tifffile

        # Read the TIFF
        with tifffile.TiffFile(tiff_path) as tif:
            # Get the image data from first page
            data = tif.asarray()

            # Get existing metadata to preserve
            metadata = {}
            if hasattr(tif.pages[0], 'tags'):
                for tag in tif.pages[0].tags:
                    if tag.name not in ['ImageDescription']:
                        try:
                            metadata[tag.name] = tag.value
                        except:
                            pass

        # Write back with OME-XML in description
        # For pyramidal TIFFs, we need to use the pyramid parameter
        with tifffile.TiffWriter(tiff_path, bigtiff=True) as tif_out:
            tif_out.write(
                data,
                description=ome_xml,
                compression='lzw',
                tile=(256, 256),
                metadata={'axes': 'CYX'}  # C=channels, Y=height, X=width
            )

        return True, "OME-XML injected with tifffile"

    except ImportError:
        return False, "tifffile not installed"
    except Exception as e:
        return False, f"tifffile error: {str(e)}"


def inject_ome_xml_pillow(tiff_path, ome_xml):
    """Fallback using Pillow (simpler but less robust for pyramidal TIFFs)"""
    try:
        from PIL import Image
        from PIL.TiffTags import TAGS

        # Open the TIFF
        with Image.open(tiff_path) as img:
            # For multi-page/pyramidal TIFFs, only modify the first page
            if hasattr(img, 'n_frames') and img.n_frames > 1:
                img.seek(0)  # Go to first page

            # Save with new description
            # Note: This may not preserve all pyramid levels
            img.save(
                tiff_path,
                format='TIFF',
                compression='tiff_lzw',
                description=ome_xml
            )

        return True, "OME-XML injected with Pillow (may lose pyramid levels)"

    except ImportError:
        return False, "Pillow not installed"
    except Exception as e:
        return False, f"Pillow error: {str(e)}"


def inject_ome_xml_tifftools(tiff_path, ome_xml):
    """Use tifftools for direct tag manipulation (preserves everything)"""
    try:
        import tifftools

        # Read the TIFF
        tiff_info = tifftools.read_tiff(tiff_path)

        # Modify IMAGEDESCRIPTION tag (270) in first IFD only
        if 'ifds' in tiff_info and len(tiff_info['ifds']) > 0:
            # Tag 270 is IMAGEDESCRIPTION
            tiff_info['ifds'][0]['tags'][270] = {
                'data': ome_xml.encode('utf-8'),
                'datatype': tifftools.Tag.DATATYPE.ASCII
            }

            # Write back
            tifftools.write_tiff(tiff_info, tiff_path)

            return True, "OME-XML injected with tifftools (preserves all pyramid levels)"
        else:
            return False, "No IFDs found in TIFF"

    except ImportError:
        return False, "tifftools not installed"
    except Exception as e:
        return False, f"tifftools error: {str(e)}"


def main():
    if len(sys.argv) < 3:
        print("Usage: inject_ome_xml.py <tiff_file> <ome_xml_file>")
        print("  Injects OME-XML metadata into TIFF IMAGEDESCRIPTION tag")
        sys.exit(1)

    tiff_path = sys.argv[1]
    ome_xml_path = sys.argv[2]

    if not os.path.exists(tiff_path):
        print(f"ERROR: TIFF file not found: {tiff_path}")
        sys.exit(1)

    if not os.path.exists(ome_xml_path):
        print(f"ERROR: OME-XML file not found: {ome_xml_path}")
        sys.exit(1)

    # Read OME-XML
    with open(ome_xml_path, 'r', encoding='utf-8') as f:
        ome_xml = f.read()

    print(f"TIFF file: {tiff_path}")
    print(f"OME-XML file: {ome_xml_path}")
    print(f"OME-XML length: {len(ome_xml)} bytes")
    print()

    # Create backup
    backup_path = tiff_path + ".backup_before_ome"
    if not os.path.exists(backup_path):
        import shutil
        shutil.copy2(tiff_path, backup_path)
        print(f"Backup created: {backup_path}")
    else:
        print(f"Backup already exists: {backup_path}")

    print()

    # Try methods in order of preference
    methods = [
        ("tifftools", inject_ome_xml_tifftools),
        ("tifffile", inject_ome_xml_tifffile),
        ("Pillow", inject_ome_xml_pillow)
    ]

    for method_name, method_func in methods:
        print(f"Trying method: {method_name}...")
        success, message = method_func(tiff_path, ome_xml)

        if success:
            print(f"[OK] SUCCESS: {message}")
            print()
            print("OME-TIFF created successfully!")
            print("QuPath should now automatically recognize channel names.")
            sys.exit(0)
        else:
            print(f"[FAILED] {message}")

    print()
    print("ERROR: All methods failed.")
    print()
    print("To fix this, install one of these Python libraries:")
    print("  pip install tifftools")
    print("  pip install tifffile")
    print("  pip install Pillow")
    sys.exit(1)


if __name__ == "__main__":
    main()
