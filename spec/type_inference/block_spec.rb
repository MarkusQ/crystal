require 'spec_helper'

describe 'Block inference' do
  it "infer type of empty block body" do
    input = parse %q(
      def foo; end

      foo do
      end
    )
    mod = infer_type input
  end

  it "infer type of block body" do
    input = parse %q(
      def foo; end

      foo do
        x = 1
      end
    )
    mod = infer_type input
    input.last.block.body.target.type.should eq(mod.int)
  end

  it "infer type of block argument" do
    input = parse %q(
      def foo
        yield 1
      end

      foo do |x|
        1
      end
    )
    mod = infer_type input
    input.last.block.args[0].type.should eq(mod.int)
  end

  it "infer type of local variable" do
    input = parse %q(
      def foo
        yield 1
      end

      y = 'a'
      foo do |x|
        y = x
      end
      y
    )
    mod = infer_type input
    input.last.type.should eq(UnionType.new(mod.char, mod.int))
  end

  it "infer type of yield" do
    input = parse %q(
      def foo
        yield
      end

      foo do
        1
      end
    )
    mod = infer_type input
    input.last.type.should eq(mod.int)
  end
end