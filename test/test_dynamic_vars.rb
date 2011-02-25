require 'helper'

class TestDynamicVars < Test::Unit::TestCase
  
  def test_01_variable
    DynamicVars.variable :foo
    assert_nil DynamicVars[:foo]

    DynamicVars.variable :bar => 5
    assert_equal 5, DynamicVars[:bar]
  end

  def test_02_raise
    assert_raise(NameError) {
      DynamicVars[:notyethere]
    }
    DynamicVars.variable :notyethere
    assert_nil DynamicVars[:notyethere]

    assert_raise(NameError) {
      DynamicVars.variable :notyethere
    }
    assert_raise(NameError) {
      DynamicVars.variable :notyethere => 9
    }
    assert_raise(NameError) {
      DynamicVars.undefine :blub
    }
  end

  def test_03_set
    DynamicVars.variable :setme
    assert_nil DynamicVars[:setme]
    DynamicVars[:setme] = 23
    assert_equal 23, DynamicVars[:setme]
    DynamicVars[:setme] = 32
    assert_equal 32, DynamicVars[:setme]
  end

  def test_04_convenience
    DynamicVars.variable :bla => 4
    assert_equal 4, DynamicVars[:bla]
    assert_equal 4, DynamicVars.bla
    DynamicVars.bla = 5
    assert_equal 5, DynamicVars.bla
    DynamicVars.bla = nil
    assert_nil DynamicVars.bla
    DynamicVars.undefine :bla
    assert_raise(NameError) {
      DynamicVars.bla
    }
  end

  def test_05_let
    DynamicVars.variable :one   => :one
    DynamicVars.variable :two   => :two
    DynamicVars.variable :three => :three

    assert_equal [:one, :two, :three],
                 [DynamicVars.one, DynamicVars.two, DynamicVars.three]

    DynamicVars.let(:one => 1, :two => :zwei) {
      # Check new binding
      assert_equal [1, :zwei, :three],
                   [DynamicVars.one, DynamicVars.two, DynamicVars.three]

      # Check update
      DynamicVars.two = 2
      assert_equal [1, 2, :three],
                   [DynamicVars.one, DynamicVars.two, DynamicVars.three]

      # Check propagation
      DynamicVars.three = 3
      assert_equal [1, 2, 3],
                   [DynamicVars.one, DynamicVars.two, DynamicVars.three]
    }

    # Only three has propgated
    assert_equal [:one, :two, 3],
                 [DynamicVars.one, DynamicVars.two, DynamicVars.three]
  end

  def test_06_thread
    DynamicVars.variable :threaded_a => :a
    DynamicVars.variable :threaded_b => :b

    th = Thread.new {
      assert_equal :a, DynamicVars.threaded_a
      assert_equal :b, DynamicVars.threaded_b
      DynamicVars.threaded_a = 1    # Will not propagate, due to thread locality
    }
    th.join

    assert_equal :a, DynamicVars.threaded_a
    assert_equal :b, DynamicVars.threaded_b
  end
  
  def test_07_handle_raised_exception_in_scope
    DynamicVars.variable :seven=> :seven
    assert_equal :seven, DynamicVars.seven

    begin
      DynamicVars.let(:seven => 7) do
        assert_equal 7, DynamicVars.seven
        raise "Testing"
      end
      fail "Should have a raising"
    rescue
      # Should be here
    end

    assert_equal :seven, DynamicVars.seven
  end
end
