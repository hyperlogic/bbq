load 'simple.dd'

BBQ.data do

  ident = Mobius.build(:a => Complex.build(:real => 1, :imag => 0),
                       :b => Complex.build(:real => 0, :imag => 0),
                       :c => Complex.build(:real => 0, :imag => 0),
                       :d => Complex.build(:real => 1, :imag => 0))

  Level.build(:tiles => (0..4).map {|i| Tile.build(:mobius => ident)},
              :numbers => (1..10).to_a)

end
