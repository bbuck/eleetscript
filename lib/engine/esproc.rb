module EleetScript
  class ESProc
    attr_accessor :proc

    def initialize(proc, engine)
      @proc = proc
      @engine = engine
    end

    def call(receiver, args, context)
      ruby_args = args.map do |arg|
        Values.to_ruby_value(arg, @engine)
      end
      Values.to_eleet_value(proc.call(*ruby_args), @engine)
    end
  end
end