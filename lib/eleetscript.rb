# frozen_string_literal: true

require_relative 'version'

# EleetScript is the entry point into the EleetScript interpreted language built
# on top of Ruby. The language is designed intentionally to lack any unsafe access
# to the underlying machine. The langauge is intended to be safe to run untrusted
# code with an 'opt-in' approach to enabling unsafe langauge access like
# intentionally adding access to the File object.
#
# Most use cases inloving EleetScript the entry point will be through an engine.
# The Engine is a stand-alone engine instance that maintains it's own version
# of the core language. This has the benefit of allowing you to completely control
# when all resources used during execution are released. This is optimal for
# use cases where engines are short lived. When you want to keep an engine around
# for an extended period as well as potentially spin up several engines at once the
# it's better to use a SharedEngine which loads the core one time and hosts the
# executed code in an unattached namespace making it safe from intervention from
# other scripts and removing the requirement to load the entire langauge core on
# each new instantiation.
module EleetScript
end

require_relative 'tools/lexer'
