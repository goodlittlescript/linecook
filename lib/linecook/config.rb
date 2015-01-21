require 'linecook/template'
require 'linecook/parser'

module Linecook
  class Config
    class << self
      def options(overrides = {})
        {
          :path => ENV["LINECOOK_PATH"] || default_template_dirs.join(":"),
          :field_sep => ',',
          :attributes => {},
        }.merge(overrides)
      end

      def setup(options = {})
        options = self.options(options)
        config  = {}

        path = options[:path]
        config[:template_dirs] = path.split(":")
        config[:field_sep] = options[:field_sep]
        config[:headers] = options[:headers]
        config[:attributes] = options[:attributes]

        new(config)
      end

      def default_template_dirs
        ["~/.linecook", "/etc/linecook"]
      end
    end

    attr_reader :template_dirs
    attr_reader :field_sep
    attr_reader :headers
    attr_reader :attributes

    def initialize(config = {})
      @template_dirs  = config.fetch(:template_dirs) { [] }
      @field_sep      = config.fetch(:field_sep, ',')
      @headers        = config.fetch(:headers, nil)
      @attributes     = config.fetch(:attributes) { {} }
    end

    def parser(source, field_names = nil)
      Parser.new(source,
        :field_sep => field_sep,
        :headers   => headers,
        :field_names => field_names,
      )
    end

    def template_files
      templates_files = {}
      templates.each_pair do |name, template|
        templates_files[name] = template.template_file
      end
      templates_files
    end

    def templates
      @templates ||= begin
        templates = {}
        template_dirs.each do |dir|
          dir = File.expand_path(dir)
          Dir.glob(File.join(dir, "**/*.{erb,lc}")).each do |file|
            name = file[dir.length + 1, file.length - dir.length - 1 - File.extname(file).length]
            template = Template.new(file, attributes)
            templates[name] ||= template
          end
        end
        templates
      end
    end
  end
end
