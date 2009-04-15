load 'simple.dd'

ident_mobius = Mobius.new({:a => Complex.new(:real => 1, :imag => 0),
	                       :b => Complex.new(:real => 0, :imag => 0),
					       :c => Complex.new(:real => 0, :imag => 0),
					       :d => Complex.new(:real => 1, :imag => 1)})

tiles = []
tiles[0] = Tile.new(:mobius => ident_mobius)
tiles[1] = Tile.new(:mobius => ident_mobius)
tiles[2] = Tile.new(:mobius => ident_mobius)
tiles[3] = Tile.new(:mobius => ident_mobius)
					
$root = Level.new :tiles => tiles

	  