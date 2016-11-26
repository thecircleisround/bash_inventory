#!/bin/bash

#Variables
INVDIR="$HOME/Documents/inventory/"
BACKUPS="$HOME/Documents/inventory/backups/"

datetime=$(date +%h-%d_%k%M)
datetimefull=$(date +%h-%d%t%r)

#TRANSFER#
transfer(){
    
    ## Needs to ask inventory number. Have options for custom entries. Ask where items are coming from and where items are going. Cat >> transfer file.
    echo "Where are you transferring FROM? (hotel_1, hotel_2, or hotel_3)"
    read origLoc
    origLoc=$(echo $origLoc | tr '[:upper:]' '[:lower:]')
    case "$origLoc" in
    hotel_1)
    origprop="0700"
    transfer1
    ;;
    hotel_2)
    origprop="0710"
    transfer1
    ;;
    hotel_3)
    origprop="0720"
    transfer1
    ;;
    *)
    echo INVALID ENTRY
    transfer
    esac
}    
transfer1(){
    echo "Where are you transferring TO? (hotel_1, hotel_2, or hotel_3)"
    read newLoc
    newLoc=$(echo $newLoc | tr '[:upper:]' '[:lower:]')
    case "$newLoc" in
    hotel_1)
    destprop="0700"
    transfer2
    ;;
    hotel_2)
    destprop="0710"
    transfer2
    ;;
    hotel_3)
    destprop="0720"
    transfer2
    ;;
    *)
    echo "INVALID ENTRY"
    transfer1
    esac
}
transfer2(){
    if [ "$choice" = "return" ]; then
        transferFile="$INVDIR""/returns/""ITEMS_RETURNED_FROM_""$origLoc""_to_""$newLoc""$datetime"".txt"
        echo -e "Items being returned from $origLoc to $newLoc on" "$datetimefull" "\n" > "$transferFile"
        return
    else
        transferFile="$INVDIR""/transfers/""TEMPORARY_TRANSFER_""$origLoc""_to_""$newLoc""$datetime"".txt"
        echo -e "Items being transferred from $origLoc to $newLoc on" "$datetimefull" "\n" > "$transferFile"
        transfer3
    fi
    
}
transfer3(){
    echo "Scan or enter the inventory number of the item you wish to transfer. Type done when you are finished. "
    read itemNumber
    if [ "$itemNumber" = "done" ]; then
    clear
    echo "You are transferring the following items: "
    cat "$transferFile"
    exit
    else
    invinfo=$(cat "$INVDIR"inventory.txt | grep -Fx -A 3 "$itemNumber" || echo "NO MATCH FOUND")
    tranInvinfo=$(cat "$INVDIR"inventory.txt | grep -Fx "$itemNumber") #this gets sent to master transfer list
    #cat inventory.txt | grep -Fx -A 3 "$itemNumber" || echo "NO MATCH FOUND" >&2
    if [ "$invinfo" = "NO MATCH FOUND" ]; then
    echo "NO MATCH FOUND"
    transfer3
else
    invcheck=$(cat "$INVDIR"transfers.txt | grep "$origprop""_""$tranInvinfo""_$destprop" || echo notfound) #Check to see if item is transferred
    if [ "$invcheck" = "notfound" ]; then 
        echo -e "$invinfo" "\n" >> "$transferFile"
        echo ""
        echo "$invinfo"
        echo -e "$origprop""_""$tranInvinfo""_$destprop" "\n" >> "$INVDIR""transfers.txt"
        echo -e "\033[0m"
        transfer3
        else
        echo "ERROR. ITEM ALREADY SCANNED" 
        transfer3
    fi
    fi
fi      

    
}
#END TRANSFER SECTION #
#RETURN#
return(){
    echo "Scan or enter the inventory number of the item you wish to return. Type done when you are finished. "
    read itemNumber
if [ "$itemNumber" = "done" ]; then
    echo "The following items have been returned: "
    cat "$transferFile"
    echo "Would you like to see outstanding items (yes or no)" #read $answer if yes then send to transfer report
    read trfranswr
    if [ "$trfranswr" = "yes" ]; then
        transferreport
        else
        startScript
    fi
    else
    invinfo=$(cat "$INVDIR"inventory.txt | grep -Fx -A 3 "$itemNumber" || echo "NO MATCH FOUND")
    tranInvinfo=$(cat "$INVDIR"inventory.txt | grep -Fx "$itemNumber") #this gets sent to master transfer list
    itemToremove="$destprop""_""$tranInvinfo"_"$origprop" #Adds destination and original property to item number. Variables are reversed from transfer section.
    removeItem=$(cat "$INVDIR"transfers.txt | grep "$itemToremove" || echo "not_found")
    echo "$itemToremove"
    if [ "$removeItem" = "not_found" ]; then
    echo -e "\nITEM NOT ON TRANSFER LIST"
    else
    sed -i '.tmp' "s/$removeItem/ \ \ /g" "$INVDIR""transfers.txt"
    rm "$INVDIR"transfers.txt.tmp
    echo -e "\n" "ITEM RETURNED"
    #cat inventory.txt | grep -Fx -A 3 "$itemNumber" || echo "NO MATCH FOUND" >&2
    fi
    if [ "$invinfo" = "NO MATCH FOUND" ]; then
        echo "NO MATCH FOUND"
        return
        else
        echo -e "\n" "$invinfo" "\n"
        echo -e "\033[0m"
        echo -e "$invinfo" "\n" >> "$transferFile"
        return
    fi
fi    
}
## Transfer Report ##
transferreport(){
transferreport="$INVDIR""reports/transfer_reports/""transferreport_""$datetime"".txt"
filecheck=$(ls -a $INVDIR | grep transfers.txt || echo "nomatch")
if [ "$filecheck" = "nomatch" ]; then
echo "Currently there are no transfers"
echo "No report generated."
exit
else
echo -e "The following items are currently on loan to other properties:\033[0:34m" "\n"
    echo -e "Transfer Report Generated $datetimefull" >> "$transferreport"
    echo -e " " >> "$transferreport"
    echo -e "The following items are currently on loan to other properties: " >> "$transferreport"
    echo -e " " >> "$transferreport"
while read p; do
    homeloc=$(echo "$p" | cut -d'_' -f1)
    loanloc=$(echo "$p" | cut -d'_' -f3)
    itemnumber=$(echo "$p" | cut -d'_' -f2)
    itemdescrip=$(cat "$INVDIR"inventory.txt | grep -Fx -A 3 "$itemnumber" || echo "nomatch" >&2 )
    case "$homeloc" in
    0700|0710|0720)
                if [ "$homeloc" = "0700" ]; then
                homeloc="Hotel_1";
                elif [ "$homeloc" = "0710" ]; then
                homeloc="Hotel_2"
                elif [ "$homeloc" = "0720" ]; then
                homeloc="Hotel_3"
            fi
            if [ "$loanloc" = "0700" ]; then
               loanloc="Hotel_1";
               elif [ "$loanloc" = "0710" ]; then
               loanloc="Hotel_2"
               elif [ "$loanloc" = "0720" ]; then
               loanloc="Hotel_3"
            fi
    echo "Item currently on loan from the $homeloc to the $loanloc"":"
    echo -e "$itemdescrip""\n"
    echo -e "$itemdescrip" >> "$transferreport"
    echo -e "Temporarily transferred to $loanloc" >> "$transferreport"
    echo -e " " >> "$transferreport"
    ;;  
    *)
    true
    ;;
    esac
done <"$INVDIR"transfers.txt
echo "END OF REPORT" >> "$transferreport"
echo "END OF REPORT" 
echo -e "\033[0m"
fi
}   

##Inventory##

searchInv(){

echo -n "Scan or enter inventory number. Type menu to return to main menu or quit to exit " 
read invnumber
if [ "$invnumber" = "menu" ]; then startScript
elif [ "$invnumber" = "quit" ]; then exit
else
        echo -e "This is the information I have for $invnumber:\033[0:34m"
        cat "$INVDIR"inventory.txt | grep  -Fx -A  3 "$invnumber" || echo "NO MATCH FOUND" >&2
        echo -e "\033[0m"
        transfer=$(cat "$INVDIR"transfers.txt | grep "$invnumber" || echo "nottransferred")
        if [ "$transfer" = "nottransferred" ];
        then
            searchInv
        else
            homeloc="$(cat "$INVDIR"transfers.txt | grep "$invnumber" | cut -d'_' -f1)"
            loanloc="$(cat "$INVDIR"transfers.txt | grep "$invnumber" | cut -d'_' -f3)"
            if [ "$homeloc" = "0700" ]; then
                homeloc="hotel_1";
                elif [ "$homeloc" = "0710" ]; then
                homeloc="hotel_2"
                elif [ "$homeloc" = "0720" ]; then
                homeloc="hotel_3"
            fi
            if [ "$loanloc" = "0700 " ]; then
               loanloc="hotel_1";
               elif [ "$loanloc" = "0710 " ]; then
               loanloc="hotel_2"
               elif [ "$loanloc" = "0720 " ]; then
               loanloc="hotel_3"
            fi
            echo "This item is currently on loan from the $homeloc to"" the" "$loanloc""!"
            searchInv
        fi  
fi
startScript
}
inventory(){
    
#For appending inventory, "for" or "until" loop will work. "for i in $INVDIR/reports/inventory; do echo "1. $i"; done read appendnumber.... until $answer = yes; for i in $INVDIR/reports/inventory; do echo "$i" echo "is this the file you are looking for? "  read answer invdoc="$i" done. 
echo -n "Scan or enter inventory number " 
read invnumber
case "$invnumber" in
    menu)
    startScript
        ;;
    quit)
    exit
        ;;
    append)
    answer=0
    mv "$invdoc" "$BACKUPS"
         until [ "$answer" = "yes" ]; do
        for i in "$INVDIR"reports/inventory/*; do
            echo "Is this the file you are looking for? "
            echo "$i"
            read answer
            if [ "$answer" = "yes" ]; then
            invdoc="$i"
            inventory
        else
            invdoc="$i"
            
        fi
        done
    done
    inventory
        ;;
    done)
    cat "$invdoc"
    echo "Would you like to run inventory report?"
    read answer
    case "$answer" in
        yes)
            inventoryreport
        ;;
        no)
        exit
        ;;
        esac
        ;;
    *)
    invcheck=$(cat "$invdoc" | grep "$invnumber" || echo notfound)
    if [ "$invcheck" = "notfound" ]; then
    echo -e "SCANNED $invnumber:\n "
        cat "$INVDIR"inventory.txt | grep  -Fx -A  3 "$invnumber"
        invinfo=$(cat "$INVDIR"inventory.txt | grep  -Fx -A  3 "$invnumber" || echo "NO MATCH FOUND")
        if [ "$invinfo" = "NO MATCH FOUND" ]; then
        echo -e  "NO MATCH FOUND\n"
        inventory
    else
        echo -e "VERIFIED\n"
        echo -e "$invinfo" >> "$invdoc"
        echo -e "VERIFIED\n" >> "$invdoc"
        inventory
    fi
    else
    echo -e "ITEM ALREADY SCANNED\n"
    inventory
fi
    esac
    startScript
}

inventoryreport(){
    unverifieddoc="$INVDIR""/reports""/unverified_inventory_report_""$datetime"".txt"
    fullreport="$INVDIR""/reports""/full_inventory_report_""$datetime"".txt"
    currentinventory=$(cat "$invdoc")
    staticinventory="$INVDIR"/inventory.txt
    clear
    echo "Here is what has been verified so far: "
    echo -e "$currentinventory\n"
    echo "Would you like to see outstanding items? Report will be generated."
    read answer
    if [ "$answer" = yes ]; then
    while read p; do
        accountedfor=$(cat "$invdoc" | grep -Fx -A 3 "$p" || echo "notaccounted")
if ! [[ "$p" =~ ^[0-9]+$ ]]; then
    true
else
        if [ "$accountedfor" = "notaccounted" ]; then
            cat "$staticinventory" | grep -Fx -A 3 "$p" >> "$unverifieddoc"
            echo -e "NOT VERIFIED\n" >> "$unverifieddoc"
        else
            true
        fi
    fi
        done <"$staticinventory"
    echo "END OF REPORT" >> "$unverifieddoc"
    cat "$unverifieddoc"
    echo -e "\nWould you like to generate full inventory report containing both verified and unverified items? "
    read answer
    if [ "$answer" = yes ]; then
        echo -e "Full inventory report generated $datetimefull\n" >> "$fullreport"
        echo -e "Verified Items\n" >> "$fullreport"
        cat "$invdoc" >> "$fullreport" 
        echo -e "-------------\n" >> "$fullreport"
        echo -e "Unverified Items\n" >> "$fullreport"
        cat "$unverifieddoc" >> "$fullreport"

    else
        startScript
    fi
    fi
        startScript
}
reports(){
    echo "What kind of report would you like to run? (Transfer or Inventory)"
    read answer
    case "$answer" in
    [T,t]ransfer)
        transferreport
        ;;
    [I,i]nventory)
     until [ "$answer" = "yes" ]; do
        for i in "$INVDIR"reports/inventory/*; do
            echo "Is this the most current inventory file? "
            echo "$i"
            read answer
            if [ "$answer" = "yes" ]; then
            invdoc="$i"
            inventoryreport
        else
            invdoc="$i"
            
        fi
        done
        done
        inventoryreport
        ;;
        esac
}
startScript(){
echo "COMPANY Inventory"
echo -e "What would you like to do?\n Type '"locate"' to search by inventory number; '"transfer"' to start temporary transfer; or '"inventory"' to begin the inventory process. If you are returning items, type '"return."' To run an inventory or transfer report type '"report."'" 
read choice
case "$choice" in
    inventory)
        invdoc="$INVDIR"reports/inventory/inventory_report"$datetime"".txt"
        echo -e "INVENTORY REPORT " >> "$invdoc"
        echo " " >> "$invdoc"
        echo "Type append to continue working on existing inventory report."
        inventory
        ;;
    locate)
        searchInv
        ;;
    transfer)
       transfer 
        ;;
    report)
        reports
        ;;
    return)
        transfer
        ;;
    quit|done|exit)
        exit
        ;;
    *)
        echo "Invalid command."
        startScript
esac
}
clear
startScript
exit
