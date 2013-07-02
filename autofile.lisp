#!/home/green/sbcl-script --script

;;; -*- Mode: LISP; Syntax: COMMON-LISP; Package: autofile; Base: 10 -*-

;;; Copyright (C) 2013  Anthony Green <green@moxielogic.com>

;;; autofile is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published
;;; by the Free Software Foundation; either version 3, or (at your
;;; option) any later version.
;;;
;;; autofile is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with autofile; see the file COPYING3.  If not see
;;; <http://www.gnu.org/licenses/>.

;;;
;;; Sorts PDF documents based on content
;;;

(ql:quickload :cl-ppcre)
(ql:quickload :cl-fad)
(ql:quickload :trivial-shell)
(ql:quickload :net-telent-date)

(defpackage :autofile
  (:use :cl :cl-user :cl-ppcre :cl-fad))

(in-package :autofile)

(defparameter *capture-dir* "/home/green/Dropbox/ScanSnap"
  "The directory from which to read PDF files.")

(defparameter *target-dir* "/home/green/TOL"
  "The top level directory of our document filing hierarchy.")

(defparameter *review-dir* "/home/green/TOL/REVIEW"
  "The directory where we'll drop files that we know need to be reviewed")

(defparameter *scanner-file* "/home/green/TOL/bin/scanners.lisp"
  "This file contains the scanner definitions.")

(defmacro defscanner (name &rest scanners)
  "This macro defines scanners used by the document sorter."
  (list 'defparameter name 
	(cons 'list
	      (mapcar (lambda (s)
			(list 'list
			      (car s)
			      (cons 'list
				    (mapcar (lambda (r)
					      `(create-scanner ,r :single-line-mode t))
					    (car (cdr s))))
			      `(create-scanner ,(car (cdr (cdr s))) :single-line-mode t)))
		      scanners))))

;; Load the scanner definitions.
(load *scanner-file*)

(defun replace-all (string part replacement &key (test #'char=))
"Returns a new string in which all the occurences of the part 
is replaced with replacement."
    (with-output-to-string (out)
      (loop with part-length = (length part)
            for old-pos = 0 then (+ pos part-length)
            for pos = (search part string
                              :start2 old-pos
                              :test test)
            do (write-string string out
                             :start old-pos
                             :end (or pos (length string)))
            when pos do (write-string replacement out)
            while pos))) 

(defun test-rulez (scan-rule contents)
  (let ((new-filename-format (car scan-rule))
	(scan-list (car (cdr scan-rule)))
	(date-match (car (cdr (cdr scan-rule))))
	(fail nil))
    (mapcar
     (lambda (scanner) 
       (if (not (scan scanner contents))
	   (setf fail t)))
     scan-list)
    (if (not fail)
	(progn
	  (if date-match
	      (multiple-value-bind (match date)
		  (scan-to-strings date-match contents)
		(declare (ignore match))
		(if (not (eq nil date))
		    (let ((utc (net.telent.date:parse-time (replace-all (aref date 0) "." "-"))))
		      (net.telent.date:with-decoding 
		       (utc)
		       (format nil new-filename-format
			       *target-dir*
			       net.telent.date:year
			       net.telent.date:month
			       net.telent.date:day-of-month)))))
	    new-filename-format))
      (not fail))))

(let ((files (list-directory *capture-dir*)))
  (mapcar (lambda (filename)
	    (if (string= (pathname-type (pathname filename)) "pdf")
		(multiple-value-bind (output error-output exit-status)
		    (trivial-shell:shell-command (concatenate 'string "pdftotext -layout "
							      (namestring filename)
							      " -"))
		  (declare (ignore error-output))
		  (if (eq exit-status 0)
		      (progn
			(mapcar (lambda (rule)
				  (let ((new-filename (test-rulez rule output)))
				    (if new-filename
					(format t "mv ~A ~A~%" filename new-filename))))
				*scanners*))))))
	  files))
		  
(sb-ext:quit)



