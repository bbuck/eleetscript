require "lang/runtime/class"
require "lang/runtime/context"
require "lang/runtime/method"
require "lang/runtime/array"
require "lang/runtime/base_classes"

module EleetScript
  class Memory
    attr_reader :root, :root_context, :root_namespace

    ROOT_OBJECTS = {
      "Object" => nil,
      "Number" => nil,
      "Integer" => "Number",
      "Float" => "Number",
      "Enumerable" => nil,
      "List" => "Enumerable",
      "String" => "Enumerable",
      "Symbol" => nil,
      "Regex" => nil,
      "IO" => nil,
      "Lambda" => nil,
      "TrueClass" => nil,
      "FalseClass" => nil,
      "NilClass" => nil,
      "Random" => nil
    }

    class << self
      def define_core_methods(&block)
        core_definers << block
      end

      def core_definers
        @core_definers ||= []
      end
    end

    def initialize
      @root_namespace = NamespaceContext.new(nil, nil)
      @root_path = File.join(File.dirname(__FILE__), "eleetscript")
    end

    def bootstrap(loader)
      return if @bootstrapped
      @bootstrapped = true

      ROOT_OBJECTS.each do |obj_name, parent_class|
        if parent_class.nil?
          root_namespace[obj_name] = EleetScriptClass.create(root_namespace, obj_name)
        else
          root_namespace[obj_name] = EleetScriptClass.create(root_namespace, obj_name, root_namespace[parent_class])
        end
      end

      @root = root_namespace["Object"].new(root_namespace)
      root_namespace.current_self = @root
      root_namespace.current_class = @root.runtime_class

      root_namespace["true"] = root_namespace["TrueClass"].new_with_value(true, root_namespace)
      root_namespace["false"] = root_namespace["FalseClass"].new_with_value(false, root_namespace)
      root_namespace["nil"] = root_namespace["NilClass"].new_with_value(nil, root_namespace)

      # Global Errors Object
      root_namespace["Errors"] = root_namespace["List"].new_with_value(ListBase.new(root_namespace.es_nil), root_namespace)

      self.class.core_definers.each do |definer_block|
        instance_eval(&definer_block)
      end

      files = Dir.glob(File.join(@root_path, "**", "*.es"))
      files.each do |file|
        loader.load(file)
      end
    end
  end
end

Dir.glob(File.join(File.dirname(__FILE__), "ruby", "**", "*")).each do |file|
  require file
end