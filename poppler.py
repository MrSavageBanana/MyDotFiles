# created with Claude. Account: Milobowler

import tkinter as tk
from tkinter import ttk, filedialog, messagebox, scrolledtext
import subprocess
import os
from pathlib import Path
import threading

class PDFToolsGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("PDF Tools Suite")
        self.root.geometry("900x700")
        
        # Create notebook for tabs
        self.notebook = ttk.Notebook(root)
        self.notebook.pack(fill='both', expand=True, padx=10, pady=10)
        
        # Create tabs
        self.create_pdfgrep_tab()
        self.create_pdfinfo_tab()
        self.create_pdfimages_tab()
        self.create_pdftotext_tab()
        self.create_pdfseparate_tab()
        self.create_pdfunite_tab()
        self.create_pdfdetach_tab()
        self.create_pdftocairo_tab()
        
    def create_pdfgrep_tab(self):
        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="PDF Grep")
        
        # Pattern input
        ttk.Label(tab, text="Search Pattern:").grid(row=0, column=0, sticky='w', padx=5, pady=5)
        self.grep_pattern = ttk.Entry(tab, width=50)
        self.grep_pattern.grid(row=0, column=1, columnspan=2, padx=5, pady=5)
        
        # File selection
        ttk.Label(tab, text="PDF File(s):").grid(row=1, column=0, sticky='w', padx=5, pady=5)
        self.grep_files = tk.Listbox(tab, height=6, width=60)
        self.grep_files.grid(row=1, column=1, rowspan=3, padx=5, pady=5)
        
        ttk.Button(tab, text="Add Files", command=lambda: self.add_files(self.grep_files)).grid(row=1, column=2, padx=5, pady=2)
        ttk.Button(tab, text="Add Folder", command=lambda: self.add_folder(self.grep_files)).grid(row=2, column=2, padx=5, pady=2)
        ttk.Button(tab, text="Clear", command=lambda: self.grep_files.delete(0, tk.END)).grid(row=3, column=2, padx=5, pady=2)
        
        # Options frame
        options_frame = ttk.LabelFrame(tab, text="Options")
        options_frame.grid(row=4, column=0, columnspan=3, padx=5, pady=10, sticky='ew')
        
        self.grep_ignore_case = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="Ignore Case (-i)", variable=self.grep_ignore_case).grid(row=0, column=0, sticky='w', padx=5)
        
        self.grep_page_number = tk.BooleanVar(value=True)
        ttk.Checkbutton(options_frame, text="Show Page Numbers (-n)", variable=self.grep_page_number).grid(row=0, column=1, sticky='w', padx=5)
        
        self.grep_count = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="Count Only (-c)", variable=self.grep_count).grid(row=0, column=2, sticky='w', padx=5)
        
        self.grep_recursive = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="Recursive (-r)", variable=self.grep_recursive).grid(row=1, column=0, sticky='w', padx=5)
        
        self.grep_fixed_strings = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="Fixed Strings (-F)", variable=self.grep_fixed_strings).grid(row=1, column=1, sticky='w', padx=5)
        
        # Execute button
        ttk.Button(tab, text="Search", command=self.run_pdfgrep).grid(row=5, column=0, columnspan=3, pady=10)
        
        # Output
        ttk.Label(tab, text="Results:").grid(row=6, column=0, sticky='w', padx=5)
        self.grep_output = scrolledtext.ScrolledText(tab, height=15, width=80)
        self.grep_output.grid(row=7, column=0, columnspan=3, padx=5, pady=5)
        
    def create_pdfinfo_tab(self):
        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="PDF Info")
        
        # File selection
        ttk.Label(tab, text="PDF File:").grid(row=0, column=0, sticky='w', padx=5, pady=5)
        self.info_file = ttk.Entry(tab, width=50)
        self.info_file.grid(row=0, column=1, padx=5, pady=5)
        ttk.Button(tab, text="Browse", command=lambda: self.browse_file(self.info_file)).grid(row=0, column=2, padx=5, pady=5)
        
        # Options
        options_frame = ttk.LabelFrame(tab, text="Options")
        options_frame.grid(row=1, column=0, columnspan=3, padx=5, pady=10, sticky='ew')
        
        self.info_meta = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="Show Metadata (-meta)", variable=self.info_meta).grid(row=0, column=0, sticky='w', padx=5)
        
        self.info_box = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="Show Boxes (-box)", variable=self.info_box).grid(row=0, column=1, sticky='w', padx=5)
        
        self.info_js = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="Show JavaScript (-js)", variable=self.info_js).grid(row=1, column=0, sticky='w', padx=5)
        
        self.info_url = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="Show URLs (-url)", variable=self.info_url).grid(row=1, column=1, sticky='w', padx=5)
        
        # Page range
        ttk.Label(tab, text="First Page (-f):").grid(row=2, column=0, sticky='w', padx=5, pady=5)
        self.info_first_page = ttk.Entry(tab, width=10)
        self.info_first_page.grid(row=2, column=1, sticky='w', padx=5, pady=5)
        
        ttk.Label(tab, text="Last Page (-l):").grid(row=3, column=0, sticky='w', padx=5, pady=5)
        self.info_last_page = ttk.Entry(tab, width=10)
        self.info_last_page.grid(row=3, column=1, sticky='w', padx=5, pady=5)
        
        # Execute button
        ttk.Button(tab, text="Get Info", command=self.run_pdfinfo).grid(row=4, column=0, columnspan=3, pady=10)
        
        # Output
        ttk.Label(tab, text="Information:").grid(row=5, column=0, sticky='w', padx=5)
        self.info_output = scrolledtext.ScrolledText(tab, height=20, width=80)
        self.info_output.grid(row=6, column=0, columnspan=3, padx=5, pady=5)
        
    def create_pdfimages_tab(self):
        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="PDF Images")
        
        # File selection
        ttk.Label(tab, text="PDF File:").grid(row=0, column=0, sticky='w', padx=5, pady=5)
        self.images_file = ttk.Entry(tab, width=50)
        self.images_file.grid(row=0, column=1, padx=5, pady=5)
        ttk.Button(tab, text="Browse", command=lambda: self.browse_file(self.images_file)).grid(row=0, column=2, padx=5, pady=5)
        
        # Output directory
        ttk.Label(tab, text="Output Folder:").grid(row=1, column=0, sticky='w', padx=5, pady=5)
        self.images_output = ttk.Entry(tab, width=50)
        self.images_output.grid(row=1, column=1, padx=5, pady=5)
        ttk.Button(tab, text="Browse", command=lambda: self.browse_folder(self.images_output)).grid(row=1, column=2, padx=5, pady=5)
        
        # Image root name
        ttk.Label(tab, text="Image Prefix:").grid(row=2, column=0, sticky='w', padx=5, pady=5)
        self.images_prefix = ttk.Entry(tab, width=30)
        self.images_prefix.insert(0, "image")
        self.images_prefix.grid(row=2, column=1, sticky='w', padx=5, pady=5)
        
        # Options
        options_frame = ttk.LabelFrame(tab, text="Options")
        options_frame.grid(row=3, column=0, columnspan=3, padx=5, pady=10, sticky='ew')
        
        self.images_list = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="List Only (-list)", variable=self.images_list).grid(row=0, column=0, sticky='w', padx=5)
        
        self.images_png = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="PNG Format (-png)", variable=self.images_png).grid(row=0, column=1, sticky='w', padx=5)
        
        self.images_jpeg = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="JPEG Format (-j)", variable=self.images_jpeg).grid(row=0, column=2, sticky='w', padx=5)
        
        self.images_tiff = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="TIFF Format (-tiff)", variable=self.images_tiff).grid(row=1, column=0, sticky='w', padx=5)
        
        self.images_all = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="All Formats (-all)", variable=self.images_all).grid(row=1, column=1, sticky='w', padx=5)
        
        # Page range
        ttk.Label(tab, text="First Page (-f):").grid(row=4, column=0, sticky='w', padx=5, pady=5)
        self.images_first_page = ttk.Entry(tab, width=10)
        self.images_first_page.grid(row=4, column=1, sticky='w', padx=5, pady=5)
        
        ttk.Label(tab, text="Last Page (-l):").grid(row=5, column=0, sticky='w', padx=5, pady=5)
        self.images_last_page = ttk.Entry(tab, width=10)
        self.images_last_page.grid(row=5, column=1, sticky='w', padx=5, pady=5)
        
        # Execute button
        ttk.Button(tab, text="Extract Images", command=self.run_pdfimages).grid(row=6, column=0, columnspan=3, pady=10)
        
        # Output
        ttk.Label(tab, text="Output:").grid(row=7, column=0, sticky='w', padx=5)
        self.images_output_text = scrolledtext.ScrolledText(tab, height=15, width=80)
        self.images_output_text.grid(row=8, column=0, columnspan=3, padx=5, pady=5)
        
    def create_pdftotext_tab(self):
        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="PDF to Text")
        
        # File selection
        ttk.Label(tab, text="PDF File:").grid(row=0, column=0, sticky='w', padx=5, pady=5)
        self.text_file = ttk.Entry(tab, width=50)
        self.text_file.grid(row=0, column=1, padx=5, pady=5)
        ttk.Button(tab, text="Browse", command=lambda: self.browse_file(self.text_file)).grid(row=0, column=2, padx=5, pady=5)
        
        # Output file
        ttk.Label(tab, text="Output File:").grid(row=1, column=0, sticky='w', padx=5, pady=5)
        self.text_output_file = ttk.Entry(tab, width=50)
        self.text_output_file.grid(row=1, column=1, padx=5, pady=5)
        ttk.Button(tab, text="Browse", command=lambda: self.browse_save_file(self.text_output_file, [("Text files", "*.txt"), ("All files", "*.*")])).grid(row=1, column=2, padx=5, pady=5)
        
        # Options
        options_frame = ttk.LabelFrame(tab, text="Options")
        options_frame.grid(row=2, column=0, columnspan=3, padx=5, pady=10, sticky='ew')
        
        self.text_layout = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="Maintain Layout (-layout)", variable=self.text_layout).grid(row=0, column=0, sticky='w', padx=5)
        
        self.text_raw = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="Raw Mode (-raw)", variable=self.text_raw).grid(row=0, column=1, sticky='w', padx=5)
        
        self.text_nopgbrk = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="No Page Breaks (-nopgbrk)", variable=self.text_nopgbrk).grid(row=1, column=0, sticky='w', padx=5)
        
        # Page range
        ttk.Label(tab, text="First Page (-f):").grid(row=3, column=0, sticky='w', padx=5, pady=5)
        self.text_first_page = ttk.Entry(tab, width=10)
        self.text_first_page.grid(row=3, column=1, sticky='w', padx=5, pady=5)
        
        ttk.Label(tab, text="Last Page (-l):").grid(row=4, column=0, sticky='w', padx=5, pady=5)
        self.text_last_page = ttk.Entry(tab, width=10)
        self.text_last_page.grid(row=4, column=1, sticky='w', padx=5, pady=5)
        
        # Execute button
        ttk.Button(tab, text="Convert to Text", command=self.run_pdftotext).grid(row=5, column=0, columnspan=3, pady=10)
        
        # Output preview
        ttk.Label(tab, text="Preview:").grid(row=6, column=0, sticky='w', padx=5)
        self.text_output = scrolledtext.ScrolledText(tab, height=15, width=80)
        self.text_output.grid(row=7, column=0, columnspan=3, padx=5, pady=5)
        
    def create_pdfseparate_tab(self):
        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="PDF Separate")
        
        # File selection
        ttk.Label(tab, text="PDF File:").grid(row=0, column=0, sticky='w', padx=5, pady=5)
        self.separate_file = ttk.Entry(tab, width=50)
        self.separate_file.grid(row=0, column=1, padx=5, pady=5)
        ttk.Button(tab, text="Browse", command=lambda: self.browse_file(self.separate_file)).grid(row=0, column=2, padx=5, pady=5)
        
        # Output pattern
        ttk.Label(tab, text="Output Pattern:").grid(row=1, column=0, sticky='w', padx=5, pady=5)
        self.separate_pattern = ttk.Entry(tab, width=50)
        self.separate_pattern.insert(0, "page-%d.pdf")
        self.separate_pattern.grid(row=1, column=1, padx=5, pady=5)
        ttk.Label(tab, text="Use %d for page number", font=('TkDefaultFont', 8, 'italic')).grid(row=2, column=1, sticky='w', padx=5)
        
        # Output directory
        ttk.Label(tab, text="Output Folder:").grid(row=3, column=0, sticky='w', padx=5, pady=5)
        self.separate_output_dir = ttk.Entry(tab, width=50)
        self.separate_output_dir.grid(row=3, column=1, padx=5, pady=5)
        ttk.Button(tab, text="Browse", command=lambda: self.browse_folder(self.separate_output_dir)).grid(row=3, column=2, padx=5, pady=5)
        
        # Page range
        ttk.Label(tab, text="First Page (-f):").grid(row=4, column=0, sticky='w', padx=5, pady=5)
        self.separate_first_page = ttk.Entry(tab, width=10)
        self.separate_first_page.grid(row=4, column=1, sticky='w', padx=5, pady=5)
        
        ttk.Label(tab, text="Last Page (-l):").grid(row=5, column=0, sticky='w', padx=5, pady=5)
        self.separate_last_page = ttk.Entry(tab, width=10)
        self.separate_last_page.grid(row=5, column=1, sticky='w', padx=5, pady=5)
        
        # Execute button
        ttk.Button(tab, text="Separate Pages", command=self.run_pdfseparate).grid(row=6, column=0, columnspan=3, pady=10)
        
        # Output
        ttk.Label(tab, text="Output:").grid(row=7, column=0, sticky='w', padx=5)
        self.separate_output = scrolledtext.ScrolledText(tab, height=15, width=80)
        self.separate_output.grid(row=8, column=0, columnspan=3, padx=5, pady=5)
        
    def create_pdfunite_tab(self):
        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="PDF Unite")
        
        # File selection
        ttk.Label(tab, text="PDF Files (in order):").grid(row=0, column=0, sticky='w', padx=5, pady=5)
        self.unite_files = tk.Listbox(tab, height=10, width=60)
        self.unite_files.grid(row=0, column=1, rowspan=4, padx=5, pady=5)
        
        ttk.Button(tab, text="Add Files", command=lambda: self.add_files(self.unite_files)).grid(row=0, column=2, padx=5, pady=2)
        ttk.Button(tab, text="Move Up", command=lambda: self.move_up(self.unite_files)).grid(row=1, column=2, padx=5, pady=2)
        ttk.Button(tab, text="Move Down", command=lambda: self.move_down(self.unite_files)).grid(row=2, column=2, padx=5, pady=2)
        ttk.Button(tab, text="Remove", command=lambda: self.remove_selected(self.unite_files)).grid(row=3, column=2, padx=5, pady=2)
        
        # Output file
        ttk.Label(tab, text="Output File:").grid(row=4, column=0, sticky='w', padx=5, pady=5)
        self.unite_output = ttk.Entry(tab, width=50)
        self.unite_output.grid(row=4, column=1, padx=5, pady=5)
        ttk.Button(tab, text="Browse", command=lambda: self.browse_save_file(self.unite_output, [("PDF files", "*.pdf")])).grid(row=4, column=2, padx=5, pady=5)
        
        # Execute button
        ttk.Button(tab, text="Merge PDFs", command=self.run_pdfunite).grid(row=5, column=0, columnspan=3, pady=10)
        
        # Output
        ttk.Label(tab, text="Output:").grid(row=6, column=0, sticky='w', padx=5)
        self.unite_output_text = scrolledtext.ScrolledText(tab, height=10, width=80)
        self.unite_output_text.grid(row=7, column=0, columnspan=3, padx=5, pady=5)
        
    def create_pdfdetach_tab(self):
        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="PDF Detach")
        
        # File selection
        ttk.Label(tab, text="PDF File:").grid(row=0, column=0, sticky='w', padx=5, pady=5)
        self.detach_file = ttk.Entry(tab, width=50)
        self.detach_file.grid(row=0, column=1, padx=5, pady=5)
        ttk.Button(tab, text="Browse", command=lambda: self.browse_file(self.detach_file)).grid(row=0, column=2, padx=5, pady=5)
        
        # Output directory
        ttk.Label(tab, text="Output Folder:").grid(row=1, column=0, sticky='w', padx=5, pady=5)
        self.detach_output_dir = ttk.Entry(tab, width=50)
        self.detach_output_dir.grid(row=1, column=1, padx=5, pady=5)
        ttk.Button(tab, text="Browse", command=lambda: self.browse_folder(self.detach_output_dir)).grid(row=1, column=2, padx=5, pady=5)
        
        # Options
        options_frame = ttk.LabelFrame(tab, text="Options")
        options_frame.grid(row=2, column=0, columnspan=3, padx=5, pady=10, sticky='ew')
        
        self.detach_list = tk.BooleanVar(value=True)
        ttk.Checkbutton(options_frame, text="List Attachments (-list)", variable=self.detach_list, command=self.toggle_detach_options).grid(row=0, column=0, sticky='w', padx=5)
        
        self.detach_saveall = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="Save All (-saveall)", variable=self.detach_saveall, command=self.toggle_detach_options).grid(row=0, column=1, sticky='w', padx=5)
        
        ttk.Label(tab, text="Save Specific (#):").grid(row=3, column=0, sticky='w', padx=5, pady=5)
        self.detach_save_num = ttk.Entry(tab, width=10)
        self.detach_save_num.grid(row=3, column=1, sticky='w', padx=5, pady=5)
        
        # Execute button
        ttk.Button(tab, text="List/Extract Attachments", command=self.run_pdfdetach).grid(row=4, column=0, columnspan=3, pady=10)
        
        # Output
        ttk.Label(tab, text="Output:").grid(row=5, column=0, sticky='w', padx=5)
        self.detach_output = scrolledtext.ScrolledText(tab, height=15, width=80)
        self.detach_output.grid(row=6, column=0, columnspan=3, padx=5, pady=5)
        
    def create_pdftocairo_tab(self):
        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="PDF Convert")
        
        # File selection
        ttk.Label(tab, text="PDF File:").grid(row=0, column=0, sticky='w', padx=5, pady=5)
        self.cairo_file = ttk.Entry(tab, width=50)
        self.cairo_file.grid(row=0, column=1, padx=5, pady=5)
        ttk.Button(tab, text="Browse", command=lambda: self.browse_file(self.cairo_file)).grid(row=0, column=2, padx=5, pady=5)
        
        # Output file
        ttk.Label(tab, text="Output File:").grid(row=1, column=0, sticky='w', padx=5, pady=5)
        self.cairo_output = ttk.Entry(tab, width=50)
        self.cairo_output.grid(row=1, column=1, padx=5, pady=5)
        ttk.Button(tab, text="Browse", command=lambda: self.browse_save_file(self.cairo_output, [("All files", "*.*")])).grid(row=1, column=2, padx=5, pady=5)
        
        # Format selection
        ttk.Label(tab, text="Output Format:").grid(row=2, column=0, sticky='w', padx=5, pady=5)
        self.cairo_format = ttk.Combobox(tab, values=["PNG", "JPEG", "TIFF", "PDF", "PS", "EPS", "SVG"], state='readonly')
        self.cairo_format.set("PNG")
        self.cairo_format.grid(row=2, column=1, sticky='w', padx=5, pady=5)
        
        # Options
        options_frame = ttk.LabelFrame(tab, text="Options")
        options_frame.grid(row=3, column=0, columnspan=3, padx=5, pady=10, sticky='ew')
        
        ttk.Label(options_frame, text="Resolution (DPI):").grid(row=0, column=0, sticky='w', padx=5, pady=5)
        self.cairo_resolution = ttk.Entry(options_frame, width=10)
        self.cairo_resolution.insert(0, "150")
        self.cairo_resolution.grid(row=0, column=1, sticky='w', padx=5, pady=5)
        
        self.cairo_singlefile = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="Single File (-singlefile)", variable=self.cairo_singlefile).grid(row=1, column=0, columnspan=2, sticky='w', padx=5)
        
        # Page range
        ttk.Label(tab, text="First Page (-f):").grid(row=4, column=0, sticky='w', padx=5, pady=5)
        self.cairo_first_page = ttk.Entry(tab, width=10)
        self.cairo_first_page.grid(row=4, column=1, sticky='w', padx=5, pady=5)
        
        ttk.Label(tab, text="Last Page (-l):").grid(row=5, column=0, sticky='w', padx=5, pady=5)
        self.cairo_last_page = ttk.Entry(tab, width=10)
        self.cairo_last_page.grid(row=5, column=1, sticky='w', padx=5, pady=5)
        
        # Execute button
        ttk.Button(tab, text="Convert", command=self.run_pdftocairo).grid(row=6, column=0, columnspan=3, pady=10)
        
        # Output
        ttk.Label(tab, text="Output:").grid(row=7, column=0, sticky='w', padx=5)
        self.cairo_output_text = scrolledtext.ScrolledText(tab, height=12, width=80)
        self.cairo_output_text.grid(row=8, column=0, columnspan=3, padx=5, pady=5)
    
    # Helper methods
    def browse_file(self, entry_widget):
        filename = filedialog.askopenfilename(filetypes=[("PDF files", "*.pdf"), ("All files", "*.*")])
        if filename:
            entry_widget.delete(0, tk.END)
            entry_widget.insert(0, filename)
    
    def browse_save_file(self, entry_widget, filetypes):
        filename = filedialog.asksaveasfilename(filetypes=filetypes)
        if filename:
            entry_widget.delete(0, tk.END)
            entry_widget.insert(0, filename)
    
    def browse_folder(self, entry_widget):
        folder = filedialog.askdirectory()
        if folder:
            entry_widget.delete(0, tk.END)
            entry_widget.insert(0, folder)
    
    def add_files(self, listbox):
        filenames = filedialog.askopenfilenames(filetypes=[("PDF files", "*.pdf"), ("All files", "*.*")])
        for filename in filenames:
            listbox.insert(tk.END, filename)
    
    def add_folder(self, listbox):
        folder = filedialog.askdirectory()
        if folder:
            listbox.insert(tk.END, folder)
    
    def move_up(self, listbox):
        selection = listbox.curselection()
        if selection and selection[0] > 0:
            idx = selection[0]
            item = listbox.get(idx)
            listbox.delete(idx)
            listbox.insert(idx - 1, item)
            listbox.selection_set(idx - 1)
    
    def move_down(self, listbox):
        selection = listbox.curselection()
        if selection and selection[0] < listbox.size() - 1:
            idx = selection[0]
            item = listbox.get(idx)
            listbox.delete(idx)
            listbox.insert(idx + 1, item)
            listbox.selection_set(idx + 1)
    
    def remove_selected(self, listbox):
        selection = listbox.curselection()
        if selection:
            listbox.delete(selection[0])

    def toggle_detach_options(self):
        if self.detach_list.get():
            self.detach_saveall.set(False)
        elif self.detach_saveall.get():
            self.detach_list.set(False)
    
    def run_command(self, cmd, output_widget, success_message="Command completed successfully"):
        """Run command in a separate thread to prevent GUI freezing"""
        def execute():
            output_widget.delete(1.0, tk.END)
            output_widget.insert(tk.END, f"Running: {' '.join(cmd)}\n\n")
            output_widget.update()
            
            try:
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
                
                if result.stdout:
                    output_widget.insert(tk.END, result.stdout)
                if result.stderr:
                    output_widget.insert(tk.END, f"\nErrors/Warnings:\n{result.stderr}")
                
                if result.returncode == 0:
                    output_widget.insert(tk.END, f"\n\n{success_message}")
                else:
                    output_widget.insert(tk.END, f"\n\nCommand failed with exit code {result.returncode}")
                    
            except subprocess.TimeoutExpired:
                output_widget.insert(tk.END, "\n\nError: Command timed out after 5 minutes")
            except FileNotFoundError:
                output_widget.insert(tk.END, f"\n\nError: Command '{cmd[0]}' not found. Make sure it's installed and in your PATH.")
            except Exception as e:
                output_widget.insert(tk.END, f"\n\nError: {str(e)}")
            
            output_widget.see(tk.END)
        
        thread = threading.Thread(target=execute)
        thread.daemon = True
        thread.start()
    
    # Command execution methods
    def run_pdfgrep(self):
        pattern = self.grep_pattern.get().strip()
        if not pattern:
            messagebox.showwarning("Missing Input", "Please enter a search pattern")
            return
        
        files = list(self.grep_files.get(0, tk.END))
        if not files:
            messagebox.showwarning("Missing Input", "Please select at least one PDF file or folder")
            return
        
        cmd = ["pdfgrep"]
        
        if self.grep_ignore_case.get():
            cmd.append("-i")
        if self.grep_page_number.get():
            cmd.append("-n")
        if self.grep_count.get():
            cmd.append("-c")
        if self.grep_recursive.get():
            cmd.append("-r")
        if self.grep_fixed_strings.get():
            cmd.append("-F")
        
        cmd.append(pattern)
        cmd.extend(files)
        
        self.run_command(cmd, self.grep_output, "Search completed")
    
    def run_pdfinfo(self):
        pdf_file = self.info_file.get().strip()
        if not pdf_file:
            messagebox.showwarning("Missing Input", "Please select a PDF file")
            return
        
        if not os.path.exists(pdf_file):
            messagebox.showerror("File Not Found", f"File not found: {pdf_file}")
            return
        
        cmd = ["pdfinfo"]
        
        if self.info_first_page.get().strip():
            cmd.extend(["-f", self.info_first_page.get().strip()])
        if self.info_last_page.get().strip():
            cmd.extend(["-l", self.info_last_page.get().strip()])
        if self.info_box.get():
            cmd.append("-box")
        if self.info_meta.get():
            cmd.append("-meta")
        if self.info_js.get():
            cmd.append("-js")
        if self.info_url.get():
            cmd.append("-url")
        
        cmd.append(pdf_file)
        
        self.run_command(cmd, self.info_output, "PDF information retrieved")
    
    def run_pdfimages(self):
        pdf_file = self.images_file.get().strip()
        if not pdf_file:
            messagebox.showwarning("Missing Input", "Please select a PDF file")
            return
        
        if not os.path.exists(pdf_file):
            messagebox.showerror("File Not Found", f"File not found: {pdf_file}")
            return
        
        if self.images_list.get():
            cmd = ["pdfimages", "-list", pdf_file]
            self.run_command(cmd, self.images_output_text, "Image list retrieved")
            return
        
        output_dir = self.images_output.get().strip()
        if not output_dir:
            messagebox.showwarning("Missing Input", "Please select an output folder")
            return
        
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
        
        prefix = self.images_prefix.get().strip() or "image"
        image_root = os.path.join(output_dir, prefix)
        
        cmd = ["pdfimages"]
        
        if self.images_first_page.get().strip():
            cmd.extend(["-f", self.images_first_page.get().strip()])
        if self.images_last_page.get().strip():
            cmd.extend(["-l", self.images_last_page.get().strip()])
        if self.images_png.get():
            cmd.append("-png")
        if self.images_jpeg.get():
            cmd.append("-j")
        if self.images_tiff.get():
            cmd.append("-tiff")
        if self.images_all.get():
            cmd.append("-all")
        
        cmd.extend([pdf_file, image_root])
        
        self.run_command(cmd, self.images_output_text, f"Images extracted to {output_dir}")
    
    def run_pdftotext(self):
        pdf_file = self.text_file.get().strip()
        if not pdf_file:
            messagebox.showwarning("Missing Input", "Please select a PDF file")
            return
        
        if not os.path.exists(pdf_file):
            messagebox.showerror("File Not Found", f"File not found: {pdf_file}")
            return
        
        output_file = self.text_output_file.get().strip()
        if not output_file:
            # Generate default output filename
            output_file = os.path.splitext(pdf_file)[0] + ".txt"
            self.text_output_file.delete(0, tk.END)
            self.text_output_file.insert(0, output_file)
        
        cmd = ["pdftotext"]
        
        if self.text_first_page.get().strip():
            cmd.extend(["-f", self.text_first_page.get().strip()])
        if self.text_last_page.get().strip():
            cmd.extend(["-l", self.text_last_page.get().strip()])
        if self.text_layout.get():
            cmd.append("-layout")
        if self.text_raw.get():
            cmd.append("-raw")
        if self.text_nopgbrk.get():
            cmd.append("-nopgbrk")
        
        cmd.extend([pdf_file, output_file])
        
        def execute_and_preview():
            self.run_command(cmd, self.text_output, f"Text extracted to {output_file}")
            # Load preview after a short delay
            self.root.after(1000, lambda: self.load_text_preview(output_file))
        
        thread = threading.Thread(target=execute_and_preview)
        thread.daemon = True
        thread.start()
    
    def load_text_preview(self, output_file):
        try:
            if os.path.exists(output_file):
                with open(output_file, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read(5000)  # Load first 5000 characters
                    self.text_output.insert(tk.END, f"\n\n--- Preview (first 5000 characters) ---\n{content}")
                    if len(content) == 5000:
                        self.text_output.insert(tk.END, "\n\n... (file continues)")
        except Exception as e:
            self.text_output.insert(tk.END, f"\n\nError loading preview: {str(e)}")
    
    def run_pdfseparate(self):
        pdf_file = self.separate_file.get().strip()
        if not pdf_file:
            messagebox.showwarning("Missing Input", "Please select a PDF file")
            return
        
        if not os.path.exists(pdf_file):
            messagebox.showerror("File Not Found", f"File not found: {pdf_file}")
            return
        
        output_dir = self.separate_output_dir.get().strip()
        if not output_dir:
            messagebox.showwarning("Missing Input", "Please select an output folder")
            return
        
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
        
        pattern = self.separate_pattern.get().strip()
        if not pattern or "%d" not in pattern:
            messagebox.showwarning("Invalid Pattern", "Output pattern must contain %d for page number")
            return
        
        output_pattern = os.path.join(output_dir, pattern)
        
        cmd = ["pdfseparate"]
        
        if self.separate_first_page.get().strip():
            cmd.extend(["-f", self.separate_first_page.get().strip()])
        if self.separate_last_page.get().strip():
            cmd.extend(["-l", self.separate_last_page.get().strip()])
        
        cmd.extend([pdf_file, output_pattern])
        
        self.run_command(cmd, self.separate_output, f"Pages separated to {output_dir}")
    
    def run_pdfunite(self):
        files = list(self.unite_files.get(0, tk.END))
        if len(files) < 2:
            messagebox.showwarning("Insufficient Files", "Please select at least 2 PDF files to merge")
            return
        
        for f in files:
            if not os.path.exists(f):
                messagebox.showerror("File Not Found", f"File not found: {f}")
                return
        
        output_file = self.unite_output.get().strip()
        if not output_file:
            messagebox.showwarning("Missing Output", "Please specify an output file")
            return
        
        cmd = ["pdfunite"]
        cmd.extend(files)
        cmd.append(output_file)
        
        self.run_command(cmd, self.unite_output_text, f"PDFs merged to {output_file}")
    
    def run_pdfdetach(self):
        pdf_file = self.detach_file.get().strip()
        if not pdf_file:
            messagebox.showwarning("Missing Input", "Please select a PDF file")
            return
        
        if not os.path.exists(pdf_file):
            messagebox.showerror("File Not Found", f"File not found: {pdf_file}")
            return
        
        cmd = ["pdfdetach"]
        
        if self.detach_list.get():
            cmd.append("-list")
            cmd.append(pdf_file)
            self.run_command(cmd, self.detach_output, "Attachment list retrieved")
        elif self.detach_saveall.get():
            output_dir = self.detach_output_dir.get().strip()
            if not output_dir:
                messagebox.showwarning("Missing Output", "Please select an output folder")
                return
            
            if not os.path.exists(output_dir):
                os.makedirs(output_dir)
            
            cmd.extend(["-saveall", "-o", output_dir, pdf_file])
            self.run_command(cmd, self.detach_output, f"All attachments saved to {output_dir}")
        elif self.detach_save_num.get().strip():
            output_dir = self.detach_output_dir.get().strip()
            if not output_dir:
                messagebox.showwarning("Missing Output", "Please select an output folder")
                return
            
            if not os.path.exists(output_dir):
                os.makedirs(output_dir)
            
            save_num = self.detach_save_num.get().strip()
            cmd.extend(["-save", save_num, "-o", output_dir, pdf_file])
            self.run_command(cmd, self.detach_output, f"Attachment #{save_num} saved to {output_dir}")
        else:
            messagebox.showwarning("No Action", "Please select list, save all, or specify attachment number")
    
    def run_pdftocairo(self):
        pdf_file = self.cairo_file.get().strip()
        if not pdf_file:
            messagebox.showwarning("Missing Input", "Please select a PDF file")
            return
        
        if not os.path.exists(pdf_file):
            messagebox.showerror("File Not Found", f"File not found: {pdf_file}")
            return
        
        output_file = self.cairo_output.get().strip()
        if not output_file:
            messagebox.showwarning("Missing Output", "Please specify an output file")
            return
        
        fmt = self.cairo_format.get().lower()
        
        cmd = ["pdftocairo", f"-{fmt}"]
        
        if self.cairo_resolution.get().strip():
            cmd.extend(["-r", self.cairo_resolution.get().strip()])
        if self.cairo_first_page.get().strip():
            cmd.extend(["-f", self.cairo_first_page.get().strip()])
        if self.cairo_last_page.get().strip():
            cmd.extend(["-l", self.cairo_last_page.get().strip()])
        if self.cairo_singlefile.get():
            cmd.append("-singlefile")
        
        cmd.extend([pdf_file, output_file])
        
        self.run_command(cmd, self.cairo_output_text, f"PDF converted to {fmt.upper()}: {output_file}")


def main():
    root = tk.Tk()
    app = PDFToolsGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
