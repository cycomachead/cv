source 'https://rubygems.org'

ruby '>= 3.0'

# Standard BibTeX parser — we previously rolled our own; the gem handles
# @string macros, brace nesting, and name parsing far more carefully.
gem 'bibtex-ruby',         '~> 6.0'

# Kramdown is the same Markdown renderer Jekyll uses, so the local preview
# matches what the deployed Jekyll site will produce.
gem 'kramdown',            '~> 2.4'
gem 'kramdown-parser-gfm', '~> 1.1'

group :development, :test do
  gem 'minitest', '~> 5.20'
  gem 'rake',     '~> 13.0'
end
