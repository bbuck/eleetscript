require "util/processed_key_hash"

module EleetScript
  class BaseContext
    @@_init_funcs = []

    attr_reader :constants, :local_vars, :global_vars, :namespaces
    attr_accessor :current_self, :current_class

    class << self
      def init_with(*func_symbols)
        @@_init_funcs += func_symbols
      end
    end

    def initialize(*args)
      init(args)
      self
    end

    def es_nil
      @_es_nil ||= self["nil"]
    end

    def root_ns
      @parent_context ? @parent_context.root_ns : nil
    end

    def namespaces
      @parent_context ? @parent_context.namespaces : {}
    end

    def global_vars
      @parent_context ? @parent_context.global_vars : {}
    end

    def instance_vars
      @current_self.instance_vars
    end

    def class_vars
      @current_self.class_vars
    end

    def local_var(name, value = nil)
      if value
        local_vars[name] = value
      else
        local_vars[name] || es_nil
      end
    end

    def [](key)
      store = fetch_var_store(key)
      if store[key]
        store[key]
      elsif @parent_context
        @parent_context[key]
      else
        es_nil
      end
    end

    def []=(key, value)
      store = fetch_var_store(key)
      store[key] = value
    end

    def respond_to_missing?(name, incl_priv = false)
      @parent_context && @parent_context.respond_to?(name, incl_priv)
    end

    def method_missing(name, *args)
      if @parent_context && @parent_context.respond_to?(name)
        @parent_context.send(name, *args)
      else
        super(name, *args)
      end
    end

    protected

    def fetch_var_store(key)
      if key[0] =~ /[A-Z]/
        constants
      elsif key[0] =~ /[a-z_]/
        local_vars
      elsif key[0] == "$"
        global_vars
      elsif key[0..1] == "@@"
        class_vars
      elsif key[0] == "@"
        instance_vars
      else
        {}
      end
    end

    def parent_context=(context)
      @parent_context = context
    end

    private

    def init(args)
      throw "Arguments for new context should contain a current self and current class (even if both are nil)." if args.length < 2
      @current_self = args.shift
      cc = if args.length > 0
        args.shift
      else
        nil
      end
      @current_class = if cc.nil?
        if @current_self
          if @current_self.class?
            @current_self
          else
            @current_self.runtime_class
          end
        else
          nil
        end
      else
        cc
      end
      @parent_context = nil
      @local_vars = ProcessedKeyHash.new
      @constants = ProcessedKeyHash.new
      @global_vars = {}
      @namespaces = {}
      @@_init_funcs.each do |symbol|
        send(symbol, *args) if respond_to?(symbol, true)
      end
    end
  end

  class NamespaceContext < BaseContext
    attr_reader :global_vars

    init_with :init_namespace

    def namespace(name)
      ns = @namespaces[name]
      if ns.nil? && @parent_context
        ns = @parent_context.namespaces[ns]
      end
      ns
    end

    def add_namespace(name, value)
      @namespaces[name] = value
    end

    def global_vars
      if @root_ns == self
        @global_vars
      else
        @root_ns.global_vars
      end
    end

    def es_nil
      @root_ns["nil"]
    end

    def root_ns
      @root_ns
    end

    def new_class_context(current_self, current_class = nil)
      ctx = ClassContext.new(current_self, current_class)
      ctx.parent_context = self
      ctx
    end

    def new_namespace_context
      ctx = NamespaceContext.new(@current_self, @current_class, @root_ns)
      ctx.parent_context = self
      ctx
    end

    private

    def init_namespace(root = nil)
      if @root_ns == nil
        @root_ns = self
        @global_vars = ProcessedKeyHash.new
        @global_vars.set_key_preprocessor do |key|
          key[0] == "$" ? key[1..-1] : key
        end
      else
        @root_ns = root
      end
    end
  end

  class ClassContext < BaseContext
    def class_vars
      @current_class.class_vars
    end

    def instance_vars
      @parent_context ? @parent_context.instance_vars : {}
    end

    def new_instance_context(instance_self)
      ctx = ClassInstanceContext.new(instance_self, current_class)
      ctx.parent_context = self
      ctx
    end

    def new_method_context(lambda_context = nil)
      ctx = MethodContext.new(current_self, current_class, lambda_context)
      ctx.parent_context = self
      ctx
    end
  end

  class ClassInstanceContext < BaseContext
    def current_class
      @parent_context.current_class
    end

    def local_vars
      {}
    end

    def new_method_context(lambda_context = nil)
      ctx = MethodContext.new(current_self, current_class, lambda_context)
      ctx.parent_context = self
      ctx
    end
  end

  class MethodContext < BaseContext
    init_with :handle_lambda_context

    def local_var(name, value = nil)
      if value
        if @lambda_context && (val = @lambda_context.local_var(name))
          @lambda_context.local_var(name, value)
        else
          local_vars[name] = value
        end
      else
        val = super
        if val == es_nil && @lambda_context
          @lambda_context.local_var(name)
        elsif val
          val
        else
          es_nil
        end
      end
    end

    private

    def handle_lambda_context(lambda_context)
      @lambda_context = lambda_context
    end
  end
end