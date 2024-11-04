#!/bin/bash

DB_NAME="library.db"

# Function to create the books table if it doesn't exist
create_tables() {
    sqlite3 $DB_NAME "CREATE TABLE IF NOT EXISTS books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        copies INTEGER NOT NULL DEFAULT 1,
        issued INTEGER NOT NULL DEFAULT 0
    );"
    
    sqlite3 $DB_NAME "CREATE TABLE IF NOT EXISTS issued_books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER,
        issued_to TEXT,
        issue_date TEXT,
        return_date TEXT,
        FOREIGN KEY (book_id) REFERENCES books(id)
    );"
}

delete_book() {
    echo "Enter book ID to delete:"
    read book_id

    # Check if the input is a valid number
    if ! [[ "$book_id" =~ ^[0-9]+$ ]]; then
        echo "Invalid book ID. Please enter a valid number."
    else
        # Execute delete command in SQLite
        sqlite3 $DB_NAME "DELETE FROM books WHERE id = $book_id;"
        
        # Check if the deletion was successful by checking the return code
        if [ $? -eq 0 ]; then
            echo "Book deleted successfully."
        else
            echo "Failed to delete the book. Please check the ID."
        fi
    fi
}

add_book() {
    echo "Enter book title:"
    read title
    echo "Enter book author:"
    read author
    echo "Enter number of copies:"
    read copies

    # checking whether inputs are empty or not
    if [ -z "$title" ] || [ -z "$author" ] || [ -z "$copies" ]; then
        echo "All fields are mandatory."
    
    elif ! [[ "$copies" =~ ^[0-9]+$ ]]; then
        echo "Number of copies must be a valid number."
    else
        
        sqlite3 $DB_NAME "INSERT INTO books (title, author, copies) VALUES ('$title', '$author', $copies);"
        echo "Book added successfully."
    fi
}


# Function to view all books
view_books() {
    sqlite3 $DB_NAME "SELECT id, title, author, copies, issued FROM books;"
}

# Function to issue a book
issue_book() {
    echo "Enter book ID to issue:"
    read book_id
    echo "Enter the name of the person issuing the book:"
    read issued_to

    issue_date=$(date '+%Y-%m-%d')
    
    sqlite3 $DB_NAME "UPDATE books SET issued = issued + 1 WHERE id = $book_id AND issued < copies;"
    sqlite3 $DB_NAME "INSERT INTO issued_books (book_id, issued_to, issue_date) VALUES ($book_id, '$issued_to', '$issue_date');"
    echo "Book issued successfully."
}

# Function to return a book
return_book() {
    echo "Enter issued book ID:"
    read issued_id
    return_date=$(date '+%Y-%m-%d')

    book_id=$(sqlite3 $DB_NAME "SELECT book_id FROM issued_books WHERE id = $issued_id;")
    sqlite3 $DB_NAME "UPDATE books SET issued = issued - 1 WHERE id = $book_id;"
    sqlite3 $DB_NAME "UPDATE issued_books SET return_date = '$return_date' WHERE id = $issued_id;"
    echo "Book returned successfully."
}

# Menu to select an option
menu() {
    echo "Library Management System"
    echo "1. Add a new book"
    echo "2. View all books"
    echo "3. Issue a book"
    echo "4. Return a book"
    echo "5. Delete a bok"
    echo "6. Exit"

    read -p "Select an option (1-5): " choice

    case $choice in
        1) add_book ;;
        2) view_books ;;
        3) issue_book ;;
        4) return_book ;;
        5) delete_book ;;
        6) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
}

# Main loop
while true; do
    create_tables
    menu
done

