# frozen_string_literal: true

describe RuboCop::Cop::Style::EachWithObject do
  subject(:cop) { described_class.new }

  it 'finds inject and reduce with passed in and returned hash' do
    expect_offense(<<-RUBY.strip_indent)
      [].inject({}) { |a, e| a }
         ^^^^^^ Use `each_with_object` instead of `inject`.

      [].reduce({}) do |a, e|
         ^^^^^^ Use `each_with_object` instead of `reduce`.
        a[e] = 1
        a[e] = 1
        a
      end
    RUBY
  end

  it 'correctly autocorrects' do
    corrected = autocorrect_source(cop, <<-END.strip_indent)
      [1, 2, 3].inject({}) do |h, i|
        h[i] = i
        h
      end
    END

    expect(corrected).to eq(['[1, 2, 3].each_with_object({}) do |i, h|',
                             '  h[i] = i',
                             '  ',
                             'end',
                             ''].join("\n"))
  end

  it 'correctly autocorrects with return value only' do
    corrected = autocorrect_source(cop, <<-END.strip_indent)
      [1, 2, 3].inject({}) do |h, i|
        h
      end
    END

    expect(corrected).to eq(['[1, 2, 3].each_with_object({}) do |i, h|',
                             '  ',
                             'end',
                             ''].join("\n"))
  end

  it 'ignores inject and reduce with passed in, but not returned hash' do
    expect_no_offenses(<<-END.strip_indent)
      [].inject({}) do |a, e|
        a + e
      end

      [].reduce({}) do |a, e|
        my_method e, a
      end
    END
  end

  it 'ignores inject and reduce with empty body' do
    expect_no_offenses(<<-END.strip_indent)
      [].inject({}) do |a, e|
      end

      [].reduce({}) { |a, e| }
    END
  end

  it 'ignores inject and reduce with condition as body' do
    expect_no_offenses(<<-END.strip_indent)
      [].inject({}) do |a, e|
        a = e if e
      end

      [].inject({}) do |a, e|
        if e
          a = e
        end
      end

      [].reduce({}) do |a, e|
        a = e ? e : 2
      end
    END
  end

  it 'ignores inject and reduce passed in symbol' do
    inspect_source(cop, '[].inject(:+)', '[].reduce(:+)')
    expect(cop.offenses).to be_empty
  end

  it 'does not blow up for reduce with no arguments' do
    expect_no_offenses('[1, 2, 3].inject { |a, e| a + e }')
  end

  it 'ignores inject/reduce with assignment to accumulator param in block' do
    expect_no_offenses(<<-END.strip_indent)
      r = [1, 2, 3].reduce({}) do |memo, item|
        memo += item > 2 ? item : 0
        memo
      end
    END
  end

  context 'when a simple literal is passed as initial value' do
    it 'ignores inject/reduce' do
      expect_no_offenses('array.reduce(0) { |a, e| a }')
    end
  end
end
