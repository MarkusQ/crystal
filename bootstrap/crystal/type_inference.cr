require "program"
require "visitor"
require "ast"
require "type_inference/*"

module Crystal
  class Program
    def infer_type(node)
      node.accept TypeVisitor.new(self)
      node
    end
  end

  class TypeVisitor < Visitor
    getter :mod

    def initialize(@mod, @vars = {} of String => Var, @scope = nil, @parent = nil, @call = nil, @owner = nil, @untyped_def = nil, @typed_def = nil, @arg_types = nil, @free_vars = nil, @yield_vars = nil)
    end

    def visit(node : ASTNode)
      true
    end

    def visit(node : BoolLiteral)
      node.type = mod.bool
    end

    def visit(node : NumberLiteral)
      node.type = case node.kind
                  when :i8
                    mod.int8
                  when :i16
                    mod.int16
                  when :i32
                    mod.int32
                  when :i64
                    mod.int64
                  when :u8
                    mod.int8
                  when :u16
                    mod.int16
                  when :u32
                    mod.int32
                  when :u64
                    mod.int64
                  when :f32
                    mod.float32
                  when :f64
                    mod.float64
                  end
    end

    def visit(node : CharLiteral)
      node.type = mod.char
    end

    def visit(node : SymbolLiteral)
      node.type = mod.symbol
    end

    def visit(node : StringLiteral)
      node.type = mod.string
    end

    def visit(node : Var)
      var = lookup_var node.name
      node.bind_to var
    end

    def end_visit(node : Expressions)
      node.bind_to node.last unless node.empty?
    end

    def visit(node : Assign)
      type_assign node.target, node.value, node
    end

    def visit(node : Def)
      @mod.add_def node
      false
    end

    def visit(node : Call)
      node.mod = @mod
      node.parent_visitor = self
      node.args.each do |arg|
        arg.accept self
      end
      node.recalculate
      false
    end

    def type_assign(target, value, node)
      value.accept self

      if target.is_a?(Var)
        var = lookup_var target.name
        target.bind_to var

        node.bind_to value
        var.bind_to node
      end

      false
    end

    def lookup_var(name)
      @vars.fetch_or_assign(name) { Var.new name }
    end
  end
end
