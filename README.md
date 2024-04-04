# Photo-Sidecar-Cleaner

This script searches for [sidecar files](#what-are-sidecar-files) of images for which the actual images no longer exist.

Features:

- Processes XMP, other sidecar files possible.
- Tested on macOS and Linux. It should also run on Windows if the [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/about) is installed.
- Accelerated through parallelization.
- Does not delete automatically; you review the candidates for deletion.

## Requirements

- Basic Knowledge of using the shell on Linux or macOS is required.
- Optional: Git installation on your computer.

## Installation

1. Download the script.
2. Make the script executable: `chmod +x photo-sidecar-cleaner.sh`.

> [!TIP]
> The script creates temporary files. Therefore, install the script in its own directory, to keep your folder clean.

## Usage

> [!NOTE]
> - Create a backup of your data before running the script.
> - Create test data. Run the script and check if the results meet your expectations.

### Search

1. Identify a folder that may contain orphaned sidecar files.
2. Copy the folder path.
3. Open the shell.
4. Change to the directory containing the script.
5. Create the search command: `photo-sidecar-cleaner.sh <Folder> xmp`  
> [!TIP]
> - You can also search for other sidecar files. Replace `xmp` with, for example, `dop` to search for sidecar files from DxO PhotoLab.
> - Exclude directories: You can speed up the search if you want to ignore certain directories. On Synology NAS systems, for example, you can exclude `@eaDir` folders. Append `@eaDir` to the search command.
6. Execute the search.

**Results:**

The following files are created in the script's directory:
| File                    | Remark                             |
| ----------------------- | ---------------------------------- |
| `delete_commands.sh`    | Sidecar files that can be deleted. |
| `found.txt`             | Image files that were found.       |
| `found_files_total.txt` | All sidecar files.                 |

> [!NOTE]
> Each time the script executes, these files will be overwritten.

### Review and Deletion

1. Check the file `delete_commands.sh` (if orphaned sidecar files were found).
2. Review the entries. Check, for example, if only sidecar files are listed.
3. Make the script executable: `chmod +x delete_commands.sh`.
4. Run the script: `./delete_commands.sh`.

**Result:** The sidecar files have been deleted.

### Update the Catalogs of Your Image Programs

#### Lightroom Classic

> [!NOTE]
> This procedure is only possible if you have configured Lightroom Classic to save metadata in XMP files. This is not the case by default. See [Metadata and XMP (Adobe Help)](https://helpx.adobe.com/lightroom-classic/help/metadata-basics-actions.html). As our [scenario shows](#why-can-there-be-orphaned-sidecar-files), it makes sense to enable the setting `Automatically write changes into XMP`. If you store metadata in the Lightroom catalog, you must search for the change manually: [
Find missing photos (Adobe Help)](https://helpx.adobe.com/lightroom-classic/help/locate-missing-photos.html).

1. Switch to Library mode.
2. Expand the Folder panel.
3. Right-click on a folder and select the command `Synchronize Folder`.
> [!NOTE]
> This command does not synchronize with the cloud.
4. Activate the option `Remove Missing Pictures`.

**Result:** The catalog is updated.

#### DxO PhotoLab

Unlike other image programs, DxO does not use a database. Therefore, an update is not necessary.

> [!NOTE]
> If you work with projects, removing image files will cause inconsistencies in DxO PhotoLab's project database. In this case, only creating a new project can help.

#### Capture One

> [!NOTE]
> Capture One usually detects changes to cataloged content automatically.

1. Switch to the Library tab.
2. Right-click on a folder and select the command `Synchronize`.
3. Activate the option `Remove Missing Pictures`.

**Result:** The catalog is updated.

## FAQ

### What are sidecar files?

Typically, metadata such as tags or ratings of photos are stored not in the photo file itself but externally. This protects the image file. Most often, sidecar files have the extension XMP. These sidecar files differ from an image file only by the extension.

Moreover, there can also be other extensions. For example, the program DxO PhotoLab saves its processing steps in DOP files. There can also be other file types. Therefore, I wrote the script so that you can search for any type.

See also: [Sidecar file (Wikipedia)](https://en.wikipedia.org/wiki/Sidecar_file)

### Why can there be orphaned sidecar files?

The cause is often an unthoughtful workflow, leading to an image ending up in different folders. Therefore, a good strategy for storing image files is worthwhile to avoid unwanted redundancies.

When we edit images with a program, the original image file usually remains unchanged. However, changes often occur to the sidecar files. With Lightroom, an image does not even need to be changed for this to happen. If we export an unchanged image file, data about the export is saved in the sidecar file. If such an image is also located elsewhere, the image files do not differ, but the sidecar files do.

If we [clean up our data structure](https://github.com/sisyphosloughs/move-photos-by-date), we can find and delete duplicate images with a duplicate search. Since the sidecar files differ, the duplicate search cannot help us here.

### Why should I delete orphaned sidecar files?

In my observation, DxO PhotoLab, Lightroom Classic, or Capture One notice when an image file is missing. This is considered an error that must be resolved manually. If hundreds of images have been removed through a duplicate search, the problem cannot be fixed in a reasonable amount of time. See, for example, [
Find missing photos (Adobe Help)](https://helpx.adobe.com/lightroom-classic/help/locate-missing-photos.html).

### Does the script automatically delete sidecar files?

No, files are only deleted if you execute the file `delete_commands.sh` created by the script. Therefore, you should check this file before you run it.

## See also

- [Move-Photos-by-Date: My script for sorting photos into folders organized by their creation date](https://github.com/sisyphosloughs/move-photos-by-date)
- [Sidecar file (Wikipedia)](https://en.wikipedia.org/wiki/Sidecar_file)
- [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/about)