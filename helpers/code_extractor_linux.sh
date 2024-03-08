#!/bin/bash
# This script extracts the contents of HTML, JS and CSS files into a nicely formatted Markdown text, so that it can be further processed by LLMs (which can be useful for AI-assisted debugging & QA).

# Name of the output Markdown file
output_file="extracted_code.md"

# Start the Markdown file with an introductory line
echo "This is some code from a web application:" > "$output_file"

# Function to add a file's content to the Markdown file
add_to_markdown() {
    local file_type=$1
    local file_name=$2
    
    # Add a header for the file
    echo -e "\nThis is the $file_type file named $file_name ($file_type is the filetype in large letters, and $file_name is the file name):\n" >> "$output_file"
    
    # Add the file's contents in a Markdown code block
    echo '```' >> "$output_file"
    cat "$file_name" >> "$output_file"
    echo '```' >> "$output_file"
    echo >> "$output_file"
}

# Find all HTML, JS, and CSS files and process them
find . -type f \( -name "*.html" -o -name "*.js" -o -name "*.css" \) | while read -r file_name; do
    case $file_name in
        *.html)
            add_to_markdown "HTML" "$file_name"
            ;;
        *.js)
            add_to_markdown "JS" "$file_name"
            ;;
        *.css)
            add_to_markdown "CSS" "$file_name"
            ;;
    esac
done

# Notify user of completion
echo "Extraction complete. Check the file $output_file."
