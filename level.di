load 'level.dd'

children = []
children[0] = BBQ::Child.new :numbers => [1,2,3]
children[1] = BBQ::Child.new :numbers => [3,4]
children[2] = BBQ::Child.new :numbers => [5]

$root = BBQ::Level.new :children => children, :bytes => [0x0a, 0x0b, 0x0c]

	  