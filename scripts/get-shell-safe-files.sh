#!/bin/bash
get_filenames()
{
    # The first argument is a format containing:
    #    the length of a header
    #    a header containing the positions and lengths of each filename
    #    the filenames
    # Looks like:
    # 16>0:44>44:52>96:54docs/models/technician_domain/code/assay.svgdocs/models/technician_domain/code/control_plate.svgdocs/models/technician_domain/code/treatment_plate.svg
    local shell_unsafe_filenames=$1

    # The name of the envvar to set, e.g., "modified_files"
    local github_envvar_name=$2

    # The length of the header precedes the header length demarcation
    # Following the example above, this is "16"
    local header_length=${shell_unsafe_filenames%%">"*}

    # This is the number (and a colon) that specifies the
    # length of the header minus this demarcation (the number and a colon).
    # +1 at the end to account for the colon after the number.
    # Example: this is "3" - the length of "16>"
    local header_demarcation_length=$(( ${#header_length} + 1 ))

    # The rest of the header following the header length demarcation.
    # Example> 0:44>44:52>96:54
    local header=${shell_unsafe_filenames:$header_demarcation_length:$header_length}

    # Store each demarcated file position in an array, separated by a colon.
    # Example: Each of "0:44" "44:52" and "96:54" are array items (minus quotes)
    local filename_lengths=(${header//>/ })

    # The space-separated filenames that the envvar will be set to
    local filenames=""
    local sep=""

    # file_demarcation is set to the items in filename_lengths, e.g. "0:44"
    for file_demarcation in "${filename_lengths[@]}"; do
      # An array whose items are the numbers separated by ":"
      # Example: 0 and 44
      # The first number indicates the starting position in the string where the filename is.
      # The second number indicates the number of characters to read following the start position.
      local filename_locations=(${file_demarcation//:/ })
      local filename_start_pos=${filename_locations[0]}
      local filename_length=$(( ${filename_locations[1]} ))

      # printf %q will safely escape the filename string for outputting into $GITHUB_OUTPUT, which Actions sources later
      local shell_unsafe_filename=${shell_unsafe_filenames:$(( $header_length + $header_demarcation_length + $filename_start_pos )):$filename_length}
      local shell_safe_filename=`printf %q "$shell_unsafe_filename"`

      filenames="${filenames}${sep}${shell_safe_filename}"
      sep=" "
    done

    echo "$github_envvar_name=$filenames"
}

# The output from awk contains a header denoting the positions of
# where the orphaned and modified files are within the string.
# This is the first numbers in the string, e.g., "169:538"
part_lengths=${CHANGED_FILES%%">"*}

# Store the number in an array
part_lengths=(${part_lengths//:/ })

# This turns the string, e.g., `"169"` into the number `169`
orphaned_files_length=$(( ${part_lengths[0]} )) # the first number, e.g., 169
modified_files_length=$(( ${part_lengths[1]} )) # the second number, e.g., 538

# $CHANGED_FILES contains the output from awk following the length numbers,
# e.g., 169:538>16>0:44>44:52>96:54docs/models/technician_domain/code/assay.svgdocs/models/technician_domain/code/control_plate.svgdocs/models/technician_domain/code/treatment_plate.svg
# ${#orphaned_files_length} gives the length of the string value, e.g., "169" is "3".
# Add 2 to account for the colon and newline.
# This operation removes the "169:538>" portion from the output.
changed_files=${CHANGED_FILES:$(( ${#orphaned_files_length} + ${#modified_files_length} + 2 ))}

if [ $orphaned_files_length -gt 0 ]; then
    shell_unsafe_orphaned_files="${changed_files:0:$orphaned_files_length}"
    get_filenames $shell_unsafe_orphaned_files "orphaned_files"
fi

if [ $modified_files_length -gt 0 ]; then
    shell_unsafe_modified_files="${changed_files:$orphaned_files_length:$modified_files_length}"
    get_filenames $shell_unsafe_modified_files "modified_files"
fi