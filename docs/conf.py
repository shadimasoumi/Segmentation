# Configuration file for the Sphinx documentation builder.

# -- Project information

project = 'Segmentation'
copyright = '2023, Shadi'
author = 'Shadi'

release = '0.1'
version = '0.1.0'

# -- General configuration

extensions = ['sphinxcontrib.matlab', 'sphinx.ext.autodoc']

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
