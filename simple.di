load 'simple.dd'

ident_mobius = BBQ::Mobius.new({:a => BBQ::Complex.new(:real => 1, :imag => 0),
	                       :b => BBQ::Complex.new(:real => 0, :imag => 0),
					       :c => BBQ::Complex.new(:real => 0, :imag => 0),
					       :d => BBQ::Complex.new(:real => 1, :imag => 0)})

tiles = []
tiles[0] = BBQ::Tile.new(:mobius => ident_mobius)
tiles[1] = BBQ::Tile.new(:mobius => ident_mobius)
tiles[2] = BBQ::Tile.new(:mobius => ident_mobius)
tiles[3] = BBQ::Tile.new(:mobius => ident_mobius)
					
$root = BBQ::Level.new :tiles => tiles, :numbers => (1..10).to_a

	  