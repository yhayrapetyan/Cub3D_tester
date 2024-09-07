#!/bin/bash

DEF_COLOR='\033[0;39m'
BLACK='\033[0;30m'
RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[0;93m'
BLUE='\033[0;94m'
MAGENTA='\033[0;95m'
CYAN='\033[0;96m'
GRAY='\033[0;90m'
WHITE='\033[0;97m'

PROGRAM=$PWD/../the_game
INVALID_MAPS="$PWD/Test_maps/invalid"
OUTPUT="$PWD/Test_results"
ERRORS_COUNT=0
UNAME=$(uname -s)

action=$1
default_action="default"

if [ $# -eq 1 ]; then
    action=$1
else
    action=$default_action
fi

case $action in
    clean)
        rm -rf Test_results
        printf ${BLUE}"\n-----------------------\n"${DEF_COLOR};
        printf ${GREEN}"  Test_results deleted"${DEF_COLOR};
        printf ${BLUE}"\n-----------------------\n\n"${DEF_COLOR};
        exit 0
        ;;
    default)
            ;;
        *)
            # Check if $action is a valid subdirectory
            subdirs=$(ls -d "$INVALID_MAPS"/* 2>/dev/null)
            folder_found=false
            for subdir in $subdirs; do
                if [ "$(basename "$subdir")" == "$action" ]; then
                    folder_to_test="$action"
                    folder_found=true
                    break
                fi
            done
            if [ "$folder_found" = false ]; then
                printf "${RED}Unknown action or folder: ${YELLOW}$action\n${DEF_COLOR}"
                printf "${BLUE}Valid actions: ${GREEN}clean\n${DEF_COLOR}"
                exit 1
            fi
            subdirs=$action
            ;;
esac

printf ${BLUE}"\n-------------------------------------------------------------\n"${DEF_COLOR};
printf ${YELLOW}"\n\t\tTEST CREATED BY: "${DEF_COLOR};
printf ${CYAN}"yuhayrap :)\t\n"${DEF_COLOR};
printf ${BLUE}"\n-------------------------------------------------------------\n"${DEF_COLOR};

make -C "$PWD/../" re

if [ -f "$PROGRAM" ]; then
	echo -n
else
	printf "${RED} ${PROGRAM} PROGRAM DOES NOT EXIST${DEF_COLOR}\n";
	exit 1
fi

rm -rf Test_results
mkdir Test_results

if [ -n "$folder_to_test" ]; then
    echo fdssfd
    subdirs="$INVALID_MAPS/$folder_to_test"
    if [ ! -d "$subdirs" ]; then
        printf "${RED}Error: The folder '$folder_to_test' does not exist.\n${DEF_COLOR}"
        exit 1
    fi
else
    subdirs=$(ls -d "$INVALID_MAPS"/* 2>/dev/null)
fi

for subdir in $subdirs; do
    test_number=1
    subdir_name=$(basename "$subdir")
    printf "${MAGENTA}\n-------------------------------------------------------------\n${DEF_COLOR}"
    printf "${CYAN}                         $subdir_name\n"
    printf "${MAGENTA}-------------------------------------------------------------\n${DEF_COLOR}"
    mkdir $OUTPUT/$subdir_name
    for file_path in "$subdir"/*; do
        if [ -f "$file_path" ]; then
            file_name="${file_path##*/}"
            printf  "${CYAN}Test ${test_number}\n${DEF_COLOR}"

            if [ "$UNAME" = "Linux" ]; then
                valgrind --leak-check=full --show-leak-kinds=all "$PROGRAM" "$file_path" > $OUTPUT/$subdir_name/$file_name 2>&1
                leak_status=$(grep -Ec 'no leaks are possible|ERROR SUMMARY: 0' $OUTPUT/$subdir_name/$file_name)
                segfault_status=$(grep -w '(SIGSEGV)' $OUTPUT/$subdir_name/$file_name)
				if [[ -n $segfault_status ]]; then
                	printf "${YELLOW} (SIGSEGV) ${DEF_COLOR}\n";
                	((ERRORS_COUNT++))
				else
					if [[ $leak_status == 2 ]]; then
						printf "${GREEN}[OK LEAKS] ${DEF_COLOR}\n\n";
					else
						printf "${RED} [KO LEAKS] ${DEF_COLOR}\n\n";
						((ERRORS_COUNT++))
					fi
       			fi
            else
				"$PROGRAM" "$file_path" > $OUTPUT/$subdir_name/$file_name 2>&1
				leak_status=$(grep -Ec "0 leaks for 0 total leaked bytes." $OUTPUT/$subdir_name/$file_name)
				if [[ -n $segfault_status ]]; then
                	printf "${YELLOW} (SIGSEGV) ${DEF_COLOR}\n";
                	((ERRORS_COUNT++))
				else
					if [[ $leak_status == 1 ]]; then
						printf "${GREEN}[OK LEAKS] ${DEF_COLOR}\n\n";
					else
						printf "${RED} [KO LEAKS] ${DEF_COLOR}\n\n";
						((ERRORS_COUNT++))
					fi
       			fi
            fi
            ((test_number++))
        fi
    done
done

if [ "$ERRORS_COUNT" -ne 0 ]; then
    printf "${RED}\nProgram has some errors${DEF_COLOR}\n\n";
else
    printf "${GREEN}\nGood job! Everything works correctly 🥳✅${DEF_COLOR}\n\n"
fi
