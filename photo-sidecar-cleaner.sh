#!/bin/bash

# Checks if the necessary parameters were passed
if [ $# -lt 2 ]; then
    echo "Usage: $0 <DirectoryPath> <FileExtension> [ExcludeDirectories]"
    echo "Example: $0 /path/to/folder xmp,dop temp,@eaDir"
    exit 1
fi

# Sets the passed parameters
SEARCH_DIR=$1 # The path of the directory to be searched
FILE_EXTENSIONS=$2 # A list of file extensions to search for
EXCLUDE_DIRS=$3 # Optional: A list of directories to be excluded from the search

# Determines the number of CPU cores for parallel processing
CORES=$(nproc)

# Defines a function to process each found entry
process_entry() {
    local entry=$1 # The full path to the file
    local base="${entry%%.*}" # Removes the file extension from the path
    local dir="$(dirname "$entry")" # Determines the directory of the file
    local filename="$(basename "$base")" # Extracts the filename without extension
    local found_files=$(find "$dir" -maxdepth 1 -type f -name "$filename.*" ! -name "$(basename "$entry")")

    # Searches for files in the same directory that have the same name but a different extension    
    if [ -n "$found_files" ]; then
        # Adds the found files to the FOUND_PAIRS list, if present
        echo "$found_files" >> "$FOUND_PAIRS"
    else
        # Generates a command to delete the file if no related files were found
        echo "rm \"$entry\"" >> "$NOT_FOUND"
    fi
}

# Initializes the output files and resets them
FILES_TOTAL="found_files_total.txt" # Stores all found files
FOUND_PAIRS="found.txt" # Stores files for which at least one related file was found
NOT_FOUND="delete_commands.sh" # Stores commands to delete files for which no related files were found
echo -n "" > "$FOUND_PAIRS"
echo -n "" > "$NOT_FOUND"
echo -n "" > "$FILES_TOTAL"

# Exports the function and variables for use in subshells
export -f process_entry
export FOUND_PAIRS
export NOT_FOUND

# Construct find command's string to exclude directories from the search
EXCLUDE_STRING=""
if [ ! -z "$EXCLUDE_DIRS" ]; then
    IFS=',' read -ra ADDR <<< "$EXCLUDE_DIRS" # Splits the EXCLUDE_DIRS variable into an array
    if [ ${#ADDR[@]} -gt 0 ]; then
        # Constructs the exclusion string for find, starting with the first directory
        EXCLUDE_STRING="-name '${ADDR[0]}'"
        for i in "${ADDR[@]:1}"; do
            # Adds additional directories to the exclusion
            EXCLUDE_STRING="$EXCLUDE_STRING -o -name '$i'"
        done
        # Encloses the exclusion string in parentheses and appends it for the find command
        EXCLUDE_STRING="-type d \( $EXCLUDE_STRING \) -prune -o"
    fi
fi

# Construct find command's include string for file extensions
INCLUDE_STRING=""
if [ ! -z "$FILE_EXTENSIONS" ]; then
    IFS=',' read -ra ADDR <<< "$FILE_EXTENSIONS" # Splits the FILE_EXTENSIONS variable into an array
    if [ ${#ADDR[@]} -gt 0 ]; then
        # Constructs the exclusion string for find, starting with the first directory
        INCLUDE_STRING="-iname '*.${ADDR[0]}'"
        for i in "${ADDR[@]:1}"; do
            # Adds additional directories to the exclusion
            INCLUDE_STRING="$INCLUDE_STRING -o -iname '*.$i'"
        done
        # Encloses the exclusion string in parentheses and appends it for the find command
        INCLUDE_STRING="-type f \( $INCLUDE_STRING \)"
    fi
fi

# Searches for files excluding the specified directories
echo "Searching for files..."
eval find "$SEARCH_DIR" $EXCLUDE_STRING $INCLUDE_STRING -print0 | xargs -0 -P "$CORES" -I {} bash -c 'echo "\""{}"\"" >> '"$FILES_TOTAL"

# Checks if the output file exists and is not empty
if [ -s "$FILES_TOTAL" ]; then
    echo "Found files are listed in $FILES_TOTAL."
    # Processes each found file in parallel
    cat "$FILES_TOTAL" | xargs -n 1 -P "$CORES" -I {} bash -c "process_entry \"{}\""
    # Counts the entries in the output files
    COUNT_FOUND=$(wc -l < "$FOUND_PAIRS")
    COUNT_NOT_FOUND=$(wc -l < "$NOT_FOUND")
    echo "$COUNT_FOUND files found that have related files (see $FOUND_PAIRS)."
    echo "$COUNT_NOT_FOUND files found that have no related files (see $NOT_FOUND)."
else
    echo "No files found."
fi