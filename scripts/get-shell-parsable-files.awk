#!/usr/bin/awk -f
function join(arr) {
    header = header_sep = ""
    next_str_start = 0
    joined = ""
    for ( i=0; i in arr; i++ )
    {
        header = header header_sep next_str_start ":" length(arr[i])
        next_str_start = next_str_start + length(arr[i])
        joined = joined arr[i]
        header_sep = ">"
    }
    return length(header) ">" header joined
}

BEGIN {
    # use null characters between modification type and filenames as the field separator
    FS="\0"
    # a technique to create a new array in awk
    delete orphaned_files[0]
    delete modified_files[0]
}

{
    change_type = $1 # Git change type - A, D, M, etc.
    $1 = "" # remove the change type from the line because all subsequent operations only need the filename
    sub(/^[ ]/, "", $0) # remove extra space Git adds to filenames from diff-tree
    gsub(/[ ]/, "\\\\ ", $0) # replace all spaces in filenames w/ literal escape sequences. the final string is "\\ "
    # Remove SVG files associated with removed PUML files
    if ( change_type ~ /^D$/ && $0 ~ /\.puml$/ )
    {
        sub(/\.puml/, ".svg", $0)
        orphaned_files[length(orphaned_files)] = $0
    }
    # Process new SVGs for added/modified PUML files
    else if ( change_type !~ /^D$/ && $0 ~ /\.puml"?$/ ) # filenames may end with a " if diff-tree quoted them
    {
        modified_files[length(modified_files)] = $0
    }
}

END {
    if ( length(orphaned_files) > 0 )
        orphaned_files_string=join(orphaned_files)

    if ( length(modified_files) > 0 )
        modified_files_string=join(modified_files)

    # output filenames and length of each string for future parsing.
    # looks like:
    # 12:25>3>0:7foo.svg7>0:8>8:8bar.pumlbaz.puml
    printf "%d:%d>%s%s", length(orphaned_files_string), length(modified_files_string), orphaned_files_string, modified_files_string
}