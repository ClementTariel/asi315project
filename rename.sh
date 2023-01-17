#!/bin/bash

QUERY=0
VERBOSE=0
CMD=''
FILES=()

usage() {
    echo 'Usage rename.sh [-q] [-v] [-h] <commande> fichier ...
Renomme les fichiers en appliquant la commande sur les noms
-q : query, demande confirmation pour chaque fichier
-v : verbeux, affiche ce qui est fait
-h : affichage de ce message d'"'"'aide
Exemple :
rename.sh '"'"'tr a-z A-Z'"'"' toto titi
renommera toto en TOTO et titi en TITI' 1>&2;
}

# Read options.
while getopts "qvh" o; do
    case "${o}" in
        q)
            QUERY=1
            ;;
        v)
            VERBOSE=1
            ;;
        
        h)
            usage
            exit
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

# Read command
if [[ $# -gt 0 ]]; then
    CMD="$1"
    shift
fi

# Read files names
while [[ $# -gt 0 ]]; do
    FILES+=($1)
    shift
done

# Check args validity.
if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "Not enough args."
    usage
    exit 1
fi

# Rename files.
for i in ${!FILES[@]}; do
    FILENAME=${FILES[$i]}

    # Check if file exists.
    if [[ ! -e "$FILENAME" ]]; then
        echo "File \"$FILENAME\" not found."
        continue
    fi
    # Check if the user has write permission for the file.
    if [[ ! -w "$FILENAME" ]]; then
        echo "You don't have write permission for file \"$FILENAME\"."
        continue
    fi

    # Confirm the command used if the verbose option is used.
    if [[ $VERBOSE = 1 ]]; then
        echo "Command : \`echo \"$FILENAME\" | $CMD\`"
    fi

    # Allow the user to interrupt the command only
    # for the current file if a problem occurs.
    trap 'echo "Command interrupted"; trap 2; continue' 2
    #NEWNAME=`eval echo "$FILENAME" | $CMD`
    NEWNAME=`echo "$FILENAME" | eval $CMD`
    trap 2

    # Check if the new file name is a path.
    FILEDIR=`expr $FILENAME : '\(.*/\)[^/]*'`
    if [[ ! -z "$FILEDIR" ]]; then
        # Check if the path exists.
        if [[ ! -d "$FILEDIR" ]]; then
            echo "Directory \"$FILEDIR\" not found."
            continue
        fi
        # Check if the user have write permission.
        if [[ ! -w "$FILEDIR" ]]; then
            echo "You don't have write permission for directory \"$FILEDIR\"."
            continue
        fi
    fi

    # Ask for the user's confirmation if the query option is used.
    if [[ $QUERY = 1 ]]; then
        echo -n "Rename \"$FILENAME\" to \"$NEWNAME\" [Y/n] ? "
        REPLY=''
        read $REPLY
        # Rewrite the confirmation prompt without the newline.
        echo -en "\033[1A\033[2K"
        echo -n "Rename \"$FILENAME\" to \"$NEWNAME\" [Y/n] ? $REPLY"
        if [[ ! ($REPLY =~ ^[Yy]$) ]]; then
            echo -e " (abort)"
            continue
        fi
        echo -e " (ok)"
    fi

    # Check if there is a conflict because of the new file name,
    # it doesn't seem safe to overwrite an already existing file.
    if [[ -e "$NEWNAME" ]]; then
        echo "File \"$NEWNAME\" already exist."
        continue
    fi

    # Rename the file.
    mv $FILENAME $NEWNAME

    # Confirm the new name if the verbose option is used.
    if [[ $VERBOSE = 1 ]]; then
        echo "File \"$FILENAME\" renamed to \"$NEWNAME\"."
    fi
    
done