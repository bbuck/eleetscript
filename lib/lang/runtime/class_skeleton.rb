module EleetScript
  NO_METHOD = "no_method"

  class EleetScriptClassSkeleton
    attr_accessor :ruby_value
    attr_reader :memory

    class << self
      def set_is_instance
        self.class_eval do
          def instance?
            true
          end
        end
      end

      def set_is_class
        self.class_eval do
          def class?
            true
          end
        end
      end
    end

    def instance?
      false
    end

    def class?
      false
    end

    def is_a?(name)
      false
    end

    def hash
      if instance?
        ruby_value.hash
      else
        name.hash
      end
    end

    def eql?(other)
      if other.kind_of?(EleetScriptClassSkeleton)
        if instance?
          return call(:is, [other]).ruby_value
        elsif class? && other.class?
          return name == other.name
        end
      end
      false
    end
  end
end