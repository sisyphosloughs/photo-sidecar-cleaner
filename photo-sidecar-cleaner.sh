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
    local entry="$1" # The full path to the file
    local dir
    dir="$(dirname "$entry")" # Determines the directory of the file
    # Strip extension from the basename only (%%.* on the full path breaks on dotted dirs)
    local filename
    filename="$(basename "$entry")"
    filename="${filename%.*}"
    local found_files
    found_files=$(find "$dir" -maxdepth 1 -type f -name "$filename.*" ! -name "$(basename "$entry")")

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

# Build find arguments without eval so paths with spaces stay one argument
find_args=("$SEARCH_DIR")

if [ -n "$EXCLUDE_DIRS" ]; then
    IFS=',' read -ra ADDR <<< "$EXCLUDE_DIRS" # Splits the EXCLUDE_DIRS variable into an array
    if [ ${#ADDR[@]} -gt 0 ]; then
        find_args+=(-type d "(" -name "${ADDR[0]}")
        for i in "${ADDR[@]:1}"; do
            find_args+=(-o -name "$i")
        done
        find_args+=(")" -prune -o)
    fi
fi

if [ -n "$FILE_EXTENSIONS" ]; then
    IFS=',' read -ra ADDR <<< "$FILE_EXTENSIONS" # Splits the FILE_EXTENSIONS variable into an array
    if [ ${#ADDR[@]} -gt 0 ]; then
        find_args+=(-type f "(" -iname "*.${ADDR[0]}")
        for i in "${ADDR[@]:1}"; do
            find_args+=(-o -iname "*.$i")
        done
        find_args+=(")")
    fi
fi

# Searches for files excluding the specified directories
echo "Searching for files..."
while IFS= read -r -d '' entry; do
    printf '%s\n' "$entry" >> "$FILES_TOTAL"
done < <(find "${find_args[@]}" -print0)

# Checks if the output file exists and is not empty
if [ -s "$FILES_TOTAL" ]; then
    echo "Found files are listed in $FILES_TOTAL."
    # Re-emit null-delimited paths so xargs -0 keeps spaces intact (macOS xargs has no -d)
    while IFS= read -r entry || [ -n "$entry" ]; do
        [ -z "$entry" ] && continue
        printf '%s\0' "$entry"
    done < "$FILES_TOTAL" | xargs -0 -P "$CORES" -I {} bash -c 'process_entry "$@"' _ {}
    # Counts the entries in the output files
    COUNT_FOUND=$(wc -l < "$FOUND_PAIRS")
    COUNT_NOT_FOUND=$(wc -l < "$NOT_FOUND")
    echo "$COUNT_FOUND files found that have related files (see $FOUND_PAIRS)."
    echo "$COUNT_NOT_FOUND files found that have no related files (see $NOT_FOUND)."
else
    echo "No files found."
fi
