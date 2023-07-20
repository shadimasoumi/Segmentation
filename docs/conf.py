# Configuration file for the Sphinx documentation builder.

# -- Project information

project = 'Segmentation'
copyright = '2023, Shadi'
author = 'Shadi'

release = '0.1'
version = '0.1.0'

# -- General configuration
import os
import sys
sys.path.append(os.path.abspath('sphinxext'))
extensions = ['sphinx.ext.autodoc','sphinxcontrib.matlab']

intersphinx_mapping = {
    'python': ('https://docs.python.org/3/', None),
    'sphinx': ('https://www.sphinx-doc.org/en/master/', None),
}
intersphinx_disabled_domains = ['std']

templates_path = ['_templates']

# -- Options for HTML output

html_theme = 'sphinx_rtd_theme'

# -- Options for EPUB output
epub_show_urls = 'footnote'


import os
# other statements
matlab_src_dir = os.path.dirname(os.path.abspath(__file__))
primary_domain = 'mat'
