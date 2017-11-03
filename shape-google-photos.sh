#!/usr/local/bin/bash

dryRun=false
targets=""

function usage {
    echo "usage: $(basename ${BASH_SOURCE[0]}) [-r] [directory]...[directory]"
    echo "  -r: open dryRun mode"

    exit 1
}

function prefix_blank {
    local prefix=" "
    for ((i=0; i<$1; i++)); do
        prefix="$prefix~~~"
    done
    echo $prefix
}

# print location.
# arg1 -- path
# arg2 -- relative path level
function print_location {
    local prefix=" "
    for ((i=0; i<$2; i++)); do
        prefix="$prefix|--"
    done
    local folder_name=$(basename "$1")
    echo $prefix $folder_name
}

# handle file
# arg1 - file's basename
# arg2 - relative path level
function deal_file {
    print_location "$1" $2
    local status_prefix=$(prefix_blank $[ $2 + 1 ])
    local lowercase_filename=$(basename "$1")
    #lowercase_filename=$(echo "$lowercase_filename" | tr '[:upper:]' '[:lower:]')
    if [[ "$lowercase_filename" =~ \?*.\.jpg$ || "$lowercase_filename" =~ \?*.\.JPG$ ]]; then
        echo $status_prefix "- bad name(???); " $(fix_bad_name_file "$1")
    fi
}

# fix bad name
# arg1 - file's basename
function fix_bad_name_file {
    action=""

    # check if .json file exists
    local jsonfile="$1.json"
    if [[ -f "$jsonfile" ]]; then
        # get title from this json file
        while read line; do
            # the line including title should look like: "title": "xxxxxxxxxxx",
            if [[ "$line" =~ "\"title\":" ]]; then
                title=$(echo "$line" | gawk -F'"' '{print $4}')
                if [ "$1" != "$title" ]; then
                    action="renamed $1 to $title"
                    if [ $dryRun = true ]; then
                        action="$action (plan)"
                    else
                        mv "$1" "$title"
                    fi
                fi
                break
            fi
        done < "$jsonfile"
    fi

    echo "$action"
}

# handle folder
# arg1 -- path
# arg2 -- relative folder level
function deal_folder {
    cd "$1"
    local folder_level=$2
    local next_level=$[ $2 + 1 ]
    print_location "$1" $2

    for file in "$1"/*; do
        if [ -d "$file" ]; then
            deal_folder "$file" $next_level
        else
            local filename=$(basename "$file")
            deal_file "$filename" $next_level
            break
        fi
        
    done
}

echo 
echo "----------"
echo "Welcome to Shape Google Takeout for Photos"
echo "----------"
echo 

while getopts :r opt; do
    case "$opt" in 
        r) dryRun=true;;
        *) echo "Unknown options $opt"
            exit 1;;
    esac
done
#
shift $[ $OPTIND - 1 ]
#
targets=("$@")

echo "dryRun Mode=$dryRun"
echo "targets=${targets[*]}"

if [ -z "$targets" ]; then
    usage
fi

echo

# can't use for ... in "${targets[@]}" due to paths with blanks
for ((i=0; i<${#targets[*]}; i++)); do
    target="${targets[i]}"
    echo "$target..."
    deal_folder "$target" 1
done
