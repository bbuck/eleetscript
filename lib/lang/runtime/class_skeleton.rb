module EleetScript
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
  end
end