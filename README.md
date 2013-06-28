autofile
========

Autofile is a simple script written in Common Lisp to help sort PDF
files based on their content.

My "paperless-office" workflow looks something like this...

1. Scan all mail and receipts with OCR-powered tools to create
   searchable PDF files.

2. Run autofile to extract text from PDF documents and generate a
   series of shell commands to rename the files and sort them into
   appropriate directories.

3. Dump paper into long term storage.

Autofile runs on simple sorting rules.  I have enough rules on my
system that it catches virtually all recurring mail and expense
receipts.  Autofile can also extract relevant date information from
the documents which is used in the new filed document name.

Modify *scanner-file* in autofile.lisp to point to your filing rules.

    (defscanner *scanners*

      ;; What follows are a series of 3 element lists.
    
      ;; The three elements are as follows:
      ;; 1. The format string for the new file name.  Arguments
      ;;    to the format string include *target-dir*,
      ;;    as well as year, month and day as extracted by the 
      ;;    third element, below.
      ;; 2. A list of regexps that must match in the PDF.
      ;; 3. A regexp to extract the date from the document.  This	
      ;;    date is used in generating the new filename.
    
      ;; Here are some examples:
    
      ;; Taxi Expense Receipts
      ("~A/Work/Expenses/NEW/~4,'0d~2,'0d~2,'0d-taxi.pdf"
       ("TAXI" "CUSTOMER COPY")
       "([0-9][0-9]/[0-9][0-9]/[0-9][0-9])")
    
       ;; Great-West Life Explanation of Benefits
       ("~A/Financial/Insurance/GreatWest/Payments/~4,'0d~2,'0d~2,'0d-gw-payment.pdf"
        ("Great-West" "WE HAVE REVIEWED YOUR CLAIM")
        "EXPLANATION\ *OF\ *BENEFITS[\ ]\+([^\ ]\+[\ ]\+[0-9]\+,[\ ]\+20[0-9][0-9])")
    
       ;; 407ETR
       ("~A/Personal/Receipts/407ETR/~4,'0d~2,'0d~2,'0d-407ETR-stmt.pdf"
        ("407 ETR" "Account summary")
        "[\ ]\+([0-9]\+[\ ]\*[A-Ya-y]\+[\ ]\+[0-9][0-9])")
     
       ;; Sheraton Hotels Expense Receipts
       ("~A/Work/Expenses/NEW/~4,'0d~2,'0d~2,'0d-hotel.pdf"
        ("Sheraton" "HOTELS & RESORTS")
        "Depart Date[\ ]\+([^\ ]\+-\+[A-Y]\+-[0-9][0-9])")
    )

Sorry for the sparse docs, and good luck!

Anthony Green
green@moxielogic.com
