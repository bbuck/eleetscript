module Cuby
  class Context
    attr_reader :locals, :constants, :current_class, :current_self

    def initialize(current_self, current_class = current_self.runtime_class)
      @locals = {}
      @constants = {}
      @current_self = current_self
      @current_class = current_class
    end

    def class_vars
      current_class.class_vars
    end

    def instance_vars
      current_self.instance_vars
    end
  end
end