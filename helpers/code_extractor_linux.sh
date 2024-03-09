#!/bin/bash
# This script extracts the contents of HTML, JS, and CSS files into a nicely formatted Markdown text, so that it can be further processed by LLMs (which can be useful for AI-assisted debugging & QA).

# Name of the output Markdown file
output_file="extracted_code.md"

# Start the Markdown file with an introductory line
echo "# Relevant Code Snippets" > "$output_file"
echo "This is the full code of my web application." >> "$output_file"

# Function to add a file's content to the Markdown file
add_to_markdown() {
    local file_type=$1
    local file_name=$2

    # Add a header for the file
    echo -e "## File Name and Path: $file_name\n## File Type: $file_type\n" >> "$output_file"

    # Add the file's contents in a Markdown code block
    echo '```' >> "$output_file"
    cat "$file_name" >> "$output_file"
    echo '```' >> "$output_file"
    echo >> "$output_file"
}

# Find all HTML, JS, and CSS files, ignoring the node_modules and helpers directories, and process them
find ../ -type d \( -name "node_modules" -o -name "helpers" \) -prune -o -type f \( -name "*.html" -o -name "*.js" -o -name "*.css" -o -name "*.ts" -o -name "*.tsx" \) -print | while read -r file_name; do
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
        *.ts)
            add_to_markdown "TS" "$file_name"
            ;;
        *.tsx)
            add_to_markdown "TSX" "$file_name"
            ;;
    esac
done

# Notify user of completion
echo "Extraction complete. Check the file $output_file."
