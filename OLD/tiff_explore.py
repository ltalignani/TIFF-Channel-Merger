import tifffile
import xml.etree.ElementTree as ET

# === Chemin vers ton fichier OME-TIFF ===
path = "C:/Users/Loic/Desktop/test-tiff-slide-master/merged_channels.tif"

# Ouvre le TIFF et extrait la balise XML OME
with tifffile.TiffFile(path) as tif:
    ome_xml = tif.ome_metadata  # Le XML complet
    if ome_xml is None:
        raise ValueError("Ce fichier ne contient pas de métadonnées OME.")

# Parse le XML pour extraire les noms de canaux
ns = {'ome': 'http://www.openmicroscopy.org/Schemas/OME/2016-06'}
root = ET.fromstring(ome_xml)

channels = []
for channel in root.findall('.//ome:Channel', ns):
    name = channel.get('Name')
    if name:
        channels.append(name)
    else:
        channels.append("Unnamed")

print("Canaux trouvés :", channels)

from tifffile import TiffFile
from ome_types import from_xml


with TiffFile(path) as tif:
    ome_xml = tif.ome_metadata

ome = from_xml(ome_xml)

for image in ome.images:
    print(f"Image : {image.name}")
    for ch in image.pixels.channels:
        print(f"  Canal : {ch.name}, λ_ex = {ch.excitation_wavelength}, λ_em = {ch.emission_wavelength}")
