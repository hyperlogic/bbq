load 'level.dd'

children = []
children[0] = BBQ::Child.new :numbers => [1,2,3]
children[1] = BBQ::Child.new :numbers => [3,4]
children[2] = BBQ::Child.new :numbers => []

$root = BBQ::Level.new :children => children

	  