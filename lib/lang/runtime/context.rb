module EleetScript
  class Context
    attr_reader :locals, :constants, :current_class, :current_self

    def initialize(current_self, current_class = nil)
      @locals = {}
      @constants = {}
      @current_self = current_self
      @current_class = if current_class
        current_class
      else
        current_self.class? ? current_self : current_self.runtime_class
      end
    end

    def class_vars
      @current_class.class_vars
    end

    def instance_vars
      if @current_self.instance?
        @current_self.instance_vars
      else
        {}
      end
    end
  end
end