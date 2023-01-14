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
renommera toto en TOTO et titi en TITI' 1>&2; exit 1;
}

while getopts "qvh" o; do
    case "${o}" in
        q)
            QUERY=1
            ;;
        v)
            VERBOSE=1
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [[ $# -gt 0 ]]; then
    CMD="$1"
    shift
fi

while [[ $# -gt 0 ]]; do
    FILES+=($1)
    shift
done

if [[ ${#FILES[@]} -eq 0 ]]; then
    usage
fi

for i in ${!FILES[@]}; do
    FILENAME=${FILES[$i]}

    if [[ ! -e "$FILENAME" ]]; then
        echo "File \"$FILENAME\" not found."
        continue
    fi
    if [[ ! -w "$FILENAME" ]]; then
        echo "You don't have write permission for file \"$FILENAME\"."
        continue
    fi

    if [[ $VERBOSE = 1 ]]; then
        echo "Command : \`echo \"$FILENAME\" | $CMD\`"
    fi

    trap 'echo "Command interrupted"; trap 2; continue' 2
    NEWNAME=`eval echo "$FILENAME" | $CMD`
    trap 2

    FILEDIR=`expr $FILENAME : '\(.*/\)[^/]*'`
    if [[ ! -z "$FILEDIR" ]]; then
        if [[ ! -d "$FILEDIR" ]]; then
            echo "Directory \"$FILEDIR\" not found."
            continue
        fi
        if [[ ! -w "$FILEDIR" ]]; then
            echo "You don't have write permission for directory \"$FILEDIR\"."
            continue
        fi
    fi

    if [[ $QUERY = 1 ]]; then
        echo -n "Rename \"$FILENAME\" to \"$NEWNAME\" [Y/n] ? "
        REPLY=''
        read $REPLY
        echo -en "\033[1A\033[2K"
        echo -n "Rename \"$FILENAME\" to \"$NEWNAME\" [Y/n] ? $REPLY"
        if [[ ! ($REPLY =~ ^[Yy]$) ]]; then
            echo -e " (abort)"
            continue
        fi
        echo -e " (ok)"
    fi

    # It doesn't seem safe to overwrite an already existing file
    if [[ -e "$NEWNAME" ]]; then
        echo "File \"$NEWNAME\" already exist."
        continue
    fi

    mv $FILENAME $NEWNAME
    if [[ $VERBOSE = 1 ]]; then
        echo "File \"$FILENAME\" renamed to \"$NEWNAME\"."
    fi
    
done