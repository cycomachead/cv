# frozen_string_literal: true

require 'yaml'
require 'pathname'
require 'date'
require 'set'

module CV
  # Loads the YAML data tree under data/. Each *.yml file becomes a key on the
  # returned data object, accessible by the file's basename (e.g.
  # data.basics, data.education). Subdirectories also become accessible
  # (e.g. data.publications -> Data wrapping data/publications/*.yml).
  class Data
    def self.load(dir = CV::DATA_DIR)
      tree, dir_keys = load_tree(Pathname.new(dir))
      new(tree, dir_keys)
    end

    def self.load_tree(dir)
      tree = {}
      dir_keys = Set.new
      dir.each_child do |entry|
        name = entry.basename(entry.extname).to_s
        if entry.directory?
          subtree, _ = load_tree(entry)
          tree[name] = subtree
          dir_keys << name
        elsif entry.extname == '.yml'
          tree[name] = YAML.safe_load(entry.read,
                                      permitted_classes: [Date, Time, Symbol],
                                      aliases: true)
        end
      end
      [tree, dir_keys]
    end

    def initialize(tree, directory_keys = Set.new)
      @tree = tree
      @directory_keys = directory_keys
    end

    def [](key)
      v = @tree[key.to_s]
      @directory_keys.include?(key.to_s) ? Data.new(v) : v
    end

    def to_h
      @tree
    end

    def keys
      @tree.keys
    end

    # Allow data.basics, data.publications.papers, etc.
    def method_missing(name, *args, &block)
      key = name.to_s
      return super unless @tree.key?(key)
      self[key]
    end

    def respond_to_missing?(name, include_private = false)
      @tree.key?(name.to_s) || super
    end
  end
end
