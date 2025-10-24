// QuPath script to set channel names for imported TIFF
// Place this script in QuPath and run after opening your merged_channels.tif

// Read channel names from the text file
import java.nio.file.Paths

// Get the current image
def imageData = getCurrentImageData()
if (imageData == null) {
    print("No image open!")
    return
}

// Get the image path and derive the channel names file path
def imagePath = imageData.getServer().getPath()
def parentDir = Paths.get(imagePath).getParent()
def channelNamesFile = parentDir.resolve("merged_channels_channels.txt").toFile()

if (!channelNamesFile.exists()) {
    print("Channel names file not found: " + channelNamesFile.getAbsolutePath())
    return
}

// Read channel names
def channelNames = channelNamesFile.readLines()
print("Found channel names: " + channelNames)

// Get the image server and update channel names
def server = imageData.getServer()
def channels = server.getMetadata().getChannels()

if (channels.size() != channelNames.size()) {
    print("Warning: Number of channels (" + channels.size() + ") doesn't match number of names (" + channelNames.size() + ")")
}

// Update channel names
for (int i = 0; i < Math.min(channels.size(), channelNames.size()); i++) {
    def channel = channels[i]
    def newName = channelNames[i].trim()
    if (!newName.isEmpty()) {
        // Create new channel with updated name
        def updatedChannel = ImageChannel.getInstance(newName, channel.getColor())
        channels[i] = updatedChannel
        print("Set channel " + i + " name to: " + newName)
    }
}

// Refresh the display
fireHierarchyUpdate()
print("Channel names updated successfully!")
print("You may need to refresh the channel panel to see changes.")

// Optional: Show channel info
print("Current channels:")
for (int i = 0; i < channels.size(); i++) {
    print("  " + i + ": " + channels[i].getName())
}