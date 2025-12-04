#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Main loop
while true; do
    echo -e "\n${BLUE}=== SCSS Pattern Manager ===${NC}\n"
    
    # Main menu
    echo "What would you like to do?"
    echo "1) Delete lines with pattern"
    echo "2) Rename/Replace pattern"
    echo "3) Exit"
    echo ""
    read -p "Choose an option (1-3): " choice

    case $choice in
    1)
        # DELETE MODE
        echo -e "\n${YELLOW}=== DELETE MODE ===${NC}\n"
        read -p "Enter pattern to search for deletion: " pattern
        
        if [ -z "$pattern" ]; then
            echo -e "${RED}Error: Pattern cannot be empty${NC}"
            exit 1
        fi
        
        echo -e "\n${BLUE}Searching for pattern: ${GREEN}'$pattern'${NC}\n"
        
        # Find and display matches
        matches=$(grep -rn "$pattern" --include="*.scss" . 2>/dev/null)
        
        if [ -z "$matches" ]; then
            echo -e "${RED}No matches found for pattern: '$pattern'${NC}"
            exit 0
        fi
        
        echo -e "${YELLOW}Lines found:${NC}"
        echo "$matches" | while IFS= read -r line; do
            echo -e "${GREEN}$line${NC}"
        done
        
        # Count matches
        count=$(echo "$matches" | wc -l)
        echo -e "\n${BLUE}Total lines found: $count${NC}\n"
        
        # Confirm deletion
        read -p "Do you want to DELETE these lines? (y/n): " confirm
        
        if [[ $confirm =~ ^[Yy]$ ]]; then
            # Perform deletion
            find . -name "*.scss" -type f -exec sed -i '/'"$pattern"'/d' {} +
            echo -e "\n${GREEN}✓ Lines deleted successfully!${NC}"
        else
            echo -e "\n${RED}✗ Deletion cancelled${NC}"
        fi
        
        # Pause before returning to menu
        read -p "Press Enter to continue..."
        ;;
        
    2)
        # RENAME/REPLACE MODE
        echo -e "\n${YELLOW}=== RENAME/REPLACE MODE ===${NC}\n"
        read -p "Enter pattern to search for: " old_pattern
        
        if [ -z "$old_pattern" ]; then
            echo -e "${RED}Error: Pattern cannot be empty${NC}"
            exit 1
        fi
        
        read -p "Enter replacement text: " new_pattern
        
        if [ -z "$new_pattern" ]; then
            echo -e "${RED}Error: Replacement text cannot be empty${NC}"
            exit 1
        fi
        
        echo -e "\n${BLUE}Searching for pattern: ${GREEN}'$old_pattern'${NC}"
        echo -e "${BLUE}Will replace with: ${GREEN}'$new_pattern'${NC}\n"
        
        # Find and display matches with context
        matches=$(grep -rn "$old_pattern" --include="*.scss" . 2>/dev/null)
        
        if [ -z "$matches" ]; then
            echo -e "${RED}No matches found for pattern: '$old_pattern'${NC}"
            exit 0
        fi
        
        echo -e "${YELLOW}Current occurrences:${NC}"
        echo "$matches" | while IFS= read -r line; do
            echo -e "${RED}$line${NC}"
        done
        
        # Show preview of changes
        echo -e "\n${YELLOW}Preview of changes:${NC}"
        while IFS= read -r line; do
            file=$(echo "$line" | cut -d: -f1)
            line_num=$(echo "$line" | cut -d: -f2)
            content=$(echo "$line" | cut -d: -f3-)
            new_content=$(echo "$content" | sed "s/$old_pattern/$new_pattern/g")
            echo -e "${BLUE}File: $file (line $line_num)${NC}"
            echo -e "${RED}  Old: $content${NC}"
            echo -e "${GREEN}  New: $new_content${NC}"
            echo ""
        done <<< "$matches"
        
        # Count matches
        count=$(echo "$matches" | wc -l)
        echo -e "${BLUE}Total occurrences found: $count${NC}\n"
        
        # Confirm replacement
        read -p "Do you want to REPLACE all occurrences? (y/n): " confirm
        
        if [[ $confirm =~ ^[Yy]$ ]]; then
            # Perform replacement
            find . -name "*.scss" -type f -exec sed -i "s/$old_pattern/$new_pattern/g" {} +
            echo -e "\n${GREEN}✓ Replacement completed successfully!${NC}"
            
            # Show confirmation
            echo -e "\n${YELLOW}Verifying changes:${NC}"
            grep -rn "$new_pattern" --include="*.scss" . 2>/dev/null | head -5
            if [ $(grep -rc "$new_pattern" --include="*.scss" . 2>/dev/null | grep -v ":0$" | wc -l) -gt 5 ]; then
                echo -e "${BLUE}... (showing first 5 results)${NC}"
            fi
        else
            echo -e "\n${RED}✗ Replacement cancelled${NC}"
        fi
        
        # Pause before returning to menu
        read -p "Press Enter to continue..."
        ;;
        
    3)
        echo -e "\n${BLUE}Goodbye!${NC}"
        exit 0
        ;;
        
    *)
        echo -e "${RED}Invalid option. Please try again.${NC}"
        sleep 1
        ;;
    esac
done
