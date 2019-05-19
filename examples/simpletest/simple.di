load 'simple.dd'

BBQ.data do

  ident = Mobius.build(:a => Imaginary.build(:real => 1, :imag => 0),
                       :b => Imaginary.build(:real => 0, :imag => 0),
                       :c => Imaginary.build(:real => 0, :imag => 0),
                       :d => Imaginary.build(:real => 1, :imag => 0))

  Level.build(:tiles => (0..4).map {|i| Tile.build(:mobius => ident)},
              :numbers => (1..10).to_a)

end
